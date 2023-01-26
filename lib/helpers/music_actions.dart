


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/models/artist_content_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../helpers/null_extension.dart';
import '../audio_player_handler.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../screens/song_played_screen.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';

enum TypePlaylist {
  songs,
  album,
  artist,
  genre,
  playlist,
  favorites,
}
class MusicActions {

  static void initSongs(
    BuildContext context,
    SongModel song, { 
      required String heroId,
    }
  ) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
    Provider.of<UIProvider>(context, listen: false).currentHeroId = heroId;
    
    musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );
    
    audioControlProvider.currentIndex = index;

    _openAudios(
      index: index,
      autoStart: false,
      audioPlayer: audioPlayer,
      appDirectory: musicPlayerProvider.appDirectory,
      currentPlaylist: musicPlayerProvider.currentPlaylist,
      seek: Duration(milliseconds: UserPreferences().lastSongDuration),
    );

    audioPlayer.positionStream.listen((duration) async {
      audioControlProvider.currentDuration = duration;
      UserPreferences().lastSongDuration = duration.inMilliseconds;
    });

    audioPlayer.currentIndexStream.listen((currentIndex) {
      if( !audioPlayer.hasNext || audioPlayer.loopMode == LoopMode.one ) return;

      audioControlProvider.currentIndex =  currentIndex.value();
      musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ audioControlProvider.currentIndex ];
      UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
    });

  }

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    TypePlaylist type, { 
      required String heroId,
      int id = 0,
    }
  ) {
    
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
    
    Provider.of<UIProvider>(context, listen: false).currentHeroId = heroId;

    final playlistToLength = musicPlayerProvider.currentPlaylist.length;
    
    switch (type) {
      case TypePlaylist.songs:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;
        break;
      case TypePlaylist.album:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.albumCollection[id].value();
        break;
      case TypePlaylist.artist:
        musicPlayerProvider.currentPlaylist = (musicPlayerProvider.artistCollection[id] ?? ArtistContentModel()).songs;
        break;
      case TypePlaylist.playlist:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.playlistCollection[id].value();
        break;
      case TypePlaylist.genre:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.genreCollection[id].value();
        break;
      case TypePlaylist.favorites:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.favoriteList;
        break;
      default:
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;
        break;
    }

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );
    audioControlProvider.currentIndex = index;

    if( musicPlayerProvider.songPlayed.id != song.id || playlistToLength != musicPlayerProvider.currentPlaylist.length ) {

      audioPlayer.stop();
      
      _openAudios(
        index: index,
        audioPlayer: audioPlayer,
        appDirectory: musicPlayerProvider.appDirectory,
        currentPlaylist: musicPlayerProvider.currentPlaylist,
      );

      audioPlayer.play();
      
      audioPlayer.positionStream.listen((duration) {
        audioControlProvider.currentDuration = duration;
        UserPreferences().lastSongDuration = duration.inMilliseconds;
      });

      audioPlayer.currentIndexStream.listen((currentIndex) {
        if( !audioPlayer.hasNext || audioPlayer.loopMode == LoopMode.one ) return;

        audioControlProvider.currentIndex =  currentIndex.value();
        musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ audioControlProvider.currentIndex ];
        UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
      });

      musicPlayerProvider.songPlayed = song;
      UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
    } else {
      audioPlayer.seek( const Duration( seconds: 0 ));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayedScreen(
          playlistId: ( TypePlaylist.playlist == type ) ? id : null,
          isPlaylist: ( TypePlaylist.playlist == type ),
        )
      )
    );
  }

  static void showCurrentPlayList(BuildContext context, ){
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: ( ctx ) => ListView.builder(
        shrinkWrap: true,
        itemCount: musicPlayerProvider.currentPlaylist.length,
        itemBuilder: (_, int i) {
          final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
          final audio = musicPlayerProvider.currentPlaylist[i];
          final currentColor = ( musicPlayerProvider.songPlayed.id == audio.id) ? AppTheme.accentColor : Colors.white;
          
          return ListTile(
            leading: Icon( Icons.music_note, color: currentColor ),
            title: Text(audio.title.value(), maxLines: 1, style: TextStyle(color: currentColor)),
            subtitle: Text(audio.artist.valueEmpty('No Artists'), maxLines: 1, style: TextStyle(color: currentColor)),
            onTap: () {
              audioPlayer.seek(Duration.zero, index: i);
              audioControlProvider.currentIndex = i;
              musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[i];
              UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
              Navigator.pop(ctx);
            },            
          );
        }
      ),
    );
  }

  static Future<bool> createArtwork(File imageTempFile, int songId) async {
    final artworkBytes = await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500);
    
    if( artworkBytes != null ) {
      await imageTempFile.writeAsBytes(artworkBytes);
      return true;
    }

    return false;
  }

  static Future<bool> deleteFile(File file) async {
    try {
      final permissionStatus = await Permission.manageExternalStorage.request();

      if( permissionStatus.isGranted && await file.exists()) {
        await file.delete(recursive: true);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  static void _openAudios({
    required AudioPlayer audioPlayer,
    required List<SongModel> currentPlaylist,
    required String appDirectory,
    required int index,
    bool autoStart = true,
    Duration? seek
  }) {
    // Define the playlist
    final playlist = ConcatenatingAudioSource(
      // Start loading next item just before reaching it
      useLazyPreparation: true,
      // Specify the playlist items
      children: currentPlaylist.map((song) => AudioSource.file(
        song.data,
        tag: MediaItem(
          id: song.id.toString(),
          title: song.title.value(),
          artist: song.artist,
          album: song.album,
          artUri: Uri.file('$appDirectory/${ song.albumId }.jpg'),
        )
      )).toList(),
    );

    audioPlayer.setAudioSource(playlist, initialIndex: index, initialPosition: seek);
    
  }

}