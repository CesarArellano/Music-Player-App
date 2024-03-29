import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../extensions/extensions.dart';
import '../models/artist_content_model.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../screens/song_played_screen.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';


enum PlaylistType {
  songs,
  album,
  artist,
  genre,
  playlist,
  favorites,
}

class MusicActions {
  
  static List<SongModel> getPlaylistType({ 
    int? id,
    required PlaylistType type,
    required MusicPlayerProvider musicPlayerProvider,
  }) {
    final playlistTypeMap = {
      PlaylistType.songs: musicPlayerProvider.songList,
      PlaylistType.album: musicPlayerProvider.albumCollection[id].value(),
      PlaylistType.artist: (musicPlayerProvider.artistCollection[id] ?? ArtistContentModel()).songs,
      PlaylistType.playlist: musicPlayerProvider.playlistCollection[id].value(),
      PlaylistType.genre: musicPlayerProvider.genreCollection[id].value(),
      PlaylistType.favorites: musicPlayerProvider.favoriteList
    };

    return playlistTypeMap[type] ?? musicPlayerProvider.songList;
  }

  static void initSongs(
    BuildContext context,
    SongModel song, { 
      required String heroId,
    }
  ) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiProvider = context.read<UIProvider>();
    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final audioControlProvider = context.read<AudioControlProvider>();
    uiProvider.currentHeroId = heroId;

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );
    
    audioControlProvider.currentIndex = index;

    openAudios(
      index: index,
      audioPlayer: audioPlayer,
      audioControlProvider: audioControlProvider,
      musicPlayerProvider: musicPlayerProvider,
      uiProvider: uiProvider,
      seek: Duration(milliseconds: UserPreferences().lastSongDuration),
    );

  }

  static void initStreams(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiProvider = context.read<UIProvider>();
    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final audioControlProvider = context.read<AudioControlProvider>();

    musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;
    
    audioPlayer.positionStream.listen((duration) {
      audioControlProvider.currentDuration = duration;
      UserPreferences().lastSongDuration = duration.inMilliseconds;
    });

    audioPlayer.currentIndexStream.listen((currentIndex) {
      if( musicPlayerProvider.currentPlaylist.isEmpty ) return;

      audioControlProvider.currentIndex = currentIndex.value();
      musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ currentIndex.value() ];
      UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
      
      uiProvider.searchDominantColorByAlbumId(
        albumId: musicPlayerProvider.songPlayed.albumId.toString(),
        appDirectory: musicPlayerProvider.appDirectory
      );
    });
  }

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    PlaylistType type, { 
      required String heroId,
      int? id,
      bool activateShuffle = false
    }
  ) {
    
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiProvider = context.read<UIProvider>();
    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final audioControlProvider = context.read<AudioControlProvider>();
    
    uiProvider.currentHeroId = heroId;

    final playlistToLength = musicPlayerProvider.currentPlaylist.length;
    
    musicPlayerProvider.currentPlaylist = getPlaylistType(
      id: id,
      type: type,
      musicPlayerProvider: musicPlayerProvider,
    );

    final index = musicPlayerProvider.currentPlaylist.indexWhere(
      (songOfList) => songOfList.id == song.id 
    );

    if( musicPlayerProvider.songPlayed.id != song.id || playlistToLength != musicPlayerProvider.currentPlaylist.length ) {

      audioPlayer.stop();
      
      openAudios(
        index: index,
        audioPlayer: audioPlayer,
        audioControlProvider: audioControlProvider,
        musicPlayerProvider: musicPlayerProvider,
        uiProvider: uiProvider
      );

    } else {
      audioPlayer.seek( const Duration( seconds: 0 ));
    }

    audioPlayer.play();
    audioPlayer.setShuffleModeEnabled(activateShuffle);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayedScreen(
          playlistId: ( PlaylistType.playlist == type ) ? id : null,
          isPlaylist: ( PlaylistType.playlist == type ),
        )
      )
    );
  }

  static void showCurrentPlayList(BuildContext context, ){
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerProvider = context.read<MusicPlayerProvider>();

    showModalBottomSheet(
      context: context,
      builder: ( ctx ) => ListView.builder(
        shrinkWrap: true,
        itemCount: musicPlayerProvider.currentPlaylist.length,
        itemBuilder: (_, int i) {
          final currentSequence = musicPlayerProvider.currentPlaylist[ ( audioPlayer.effectiveIndices?[i] ).value() ];
      
          final audio = SongModel({
            '_id': currentSequence.id,
            'title':currentSequence.title,
            'artist': currentSequence.artist,
          });
          final currentColor = ( musicPlayerProvider.songPlayed.id == audio.id) ? AppTheme.accentColor : Colors.white;
          
          return ListTile(
            leading: Icon( Icons.music_note, color: currentColor ),
            title: Text(audio.title.value(), maxLines: 1, style: TextStyle(color: currentColor)),
            subtitle: Text(audio.artist.valueEmpty('No Artists'), maxLines: 1, style: TextStyle(color: currentColor)),
            onTap: () {
              audioPlayer.seek(Duration.zero, index: i);
              audioPlayer.play();
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

  static void openAudios({
    required int index,
    required AudioPlayer audioPlayer,
    required AudioControlProvider audioControlProvider,
    required MusicPlayerProvider musicPlayerProvider,
    required UIProvider uiProvider,
    Duration? seek
  }) {

    final playlist = ConcatenatingAudioSource(
      children: musicPlayerProvider.currentPlaylist.map((song) => AudioSource.file(
        song.data,
        tag: MediaItem(
          id: song.id.value().toString(),
          title: song.title.value(),
          album: song.album,
          artist: song.artist,
          duration: Duration(milliseconds: song.duration.value()),
          genre: song.genre,
          artUri: Uri.file('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg'),
        )
      )).toList(),
    );

    audioPlayer.setAudioSource(playlist, initialIndex: index, initialPosition: seek);
    audioControlProvider.currentIndex = index;
    musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ index ];
    UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
    
    uiProvider.searchDominantColorByAlbumId(
      albumId: musicPlayerProvider.songPlayed.albumId.toString(),
      appDirectory: musicPlayerProvider.appDirectory
    );
  }

}