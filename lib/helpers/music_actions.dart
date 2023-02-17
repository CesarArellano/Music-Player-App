


import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/models/artist_content_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
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

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );
    
    audioControlProvider.currentIndex = index;

    openAudios(
      index: index,
      audioPlayer: audioPlayer,
      audioControlProvider: audioControlProvider,
      musicPlayerProvider: musicPlayerProvider,
      seek: Duration(milliseconds: UserPreferences().lastSongDuration),
    );

  }

  static void initStreams(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);

    musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;
    
    audioPlayer.positionStream.listen((duration) async {
      audioControlProvider.currentDuration = duration;
      UserPreferences().lastSongDuration = duration.inMilliseconds;
    });
    
    audioPlayer.currentIndexStream.listen((currentIndex) {
      if( musicPlayerProvider.currentPlaylist.isEmpty ) return;
      audioControlProvider.currentIndex = currentIndex.value();
      musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ currentIndex.value() ];
      UserPreferences().lastSongId = musicPlayerProvider.songPlayed.id;
    });
  }

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    TypePlaylist type, { 
      required String heroId,
      int id = 0,
      bool activateShuffle = false
    }
  ) {
    
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    
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
      );
    } else {
      audioPlayer.seek( const Duration( seconds: 0 ));
    }

    audioPlayer.play();
    audioPlayer.setShuffleModeEnabled(activateShuffle);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SongPlayedScreen()
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
    final artworkBytes = await audioPlayerHandler.get<OnAudioQuery>().queryArtwork(songId, ArtworkType.AUDIO, size: 500);
    
    if( artworkBytes != null ) {
      await imageTempFile.writeAsBytes(artworkBytes);
      return true;
    }

    return false;
  }
  static void openAudios({
    required int index,
    required AudioPlayer audioPlayer,
    required AudioControlProvider audioControlProvider,
    required MusicPlayerProvider musicPlayerProvider,
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
  }

}