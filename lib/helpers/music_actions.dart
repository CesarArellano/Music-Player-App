
import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../screens/song_played_screen.dart';

enum TypePlaylist {
  songs,
  album,
  artist,
  genre
}
class MusicActions {

  static void songPlayAndPause(BuildContext context, SongModel song, TypePlaylist type, { id = 0 }) async {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);


    musicPlayerProvider.currentPlaylist = ( type == TypePlaylist.songs )
      ? musicPlayerProvider.songList
      : ( type == TypePlaylist.album)
        ? musicPlayerProvider.albumCollection[id]!
        : ( type == TypePlaylist.artist) 
          ? musicPlayerProvider.artistCollection[id]!
          : musicPlayerProvider.genreCollection[id]!;

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );

    if( musicPlayerProvider.songPlayed.title != song.title ) {
      audioPlayer.stop();
      audioPlayer.open(
        Playlist(
          audios: [
            ...musicPlayerProvider.currentPlaylist.map((song) => Audio.file(
              song.data,
              metas: Metas(
                album: song.album,
                artist: song.artist,
                title: song.title,
                id: song.id.toString(),
                image: const MetasImage.asset('assets/images/background.jpg'),
              )
            ))
          ],
          startIndex: index,
        ),
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
        showNotification: true,
      );
      
      audioPlayer.currentPosition.listen((duration) {
        audioControlProvider.currentDuration = duration;
      });

      audioPlayer.playlistAudioFinished.listen((playing) {
        if( musicPlayerProvider.songPlayed.title == song.title || !playing.hasNext ) return;
        
        audioControlProvider.currentIndex = playing.playlist.nextIndex ?? audioControlProvider.currentIndex + 1;
        musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ audioControlProvider.currentIndex ];
      });

      musicPlayerProvider.songPlayed = song;
    } else {
      audioPlayer.seek( const Duration( seconds: 0 ));
    }

    PageTransitions(
      context: context,
      child: const SongPlayedScreen(),
      animation: AnimationType.slideUp,
      duration: const Duration( milliseconds:  300 ),
      reverseDuration: const Duration( milliseconds:  300),
      curve: Curves.easeOut,
    );
  }
}