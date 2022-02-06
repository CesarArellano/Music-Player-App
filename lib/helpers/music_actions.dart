import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:music_player_app/providers/music_player_provider.dart';

import '../providers/audio_control_provider.dart';
import '../screens/song_played_screen.dart';

class MusicActions {

  static void songPlayAndPause(BuildContext context, SongModel song) async {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);

    final index = musicPlayerProvider.songList.indexWhere((songOfList) => songOfList.id == song.id );
    audioControlProvider.currentIndex = index;

    if( musicPlayerProvider.songPlayed.title != song.title ) {
      musicPlayerProvider.audioPlayer.stop();
      musicPlayerProvider.audioPlayer.open(
        Playlist(
          audios: [
            ...musicPlayerProvider.songList.map((song) => Audio.file(
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
          startIndex: index
        ),
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
        showNotification: true,
      );
      musicPlayerProvider.audioPlayer.currentPosition.listen((duration) {
        audioControlProvider.current = duration;
        if( duration.compareTo( Duration( milliseconds: musicPlayerProvider.songPlayed.duration! ))  == 0 ) {
          audioControlProvider.currentIndex += 1;
          musicPlayerProvider.songPlayed = musicPlayerProvider.songList[ audioControlProvider.currentIndex ];
        }
      });

      musicPlayerProvider.songPlayed = song;
    } else {
      if( musicPlayerProvider.audioPlayer.isPlaying.value ) {
        musicPlayerProvider.audioPlayer.stop();
        musicPlayerProvider.audioPlayer.play();
      }
    }

    PageTransitions(
      context: context, // BuildContext
      child: const SongPlayedScreen(), // Widget
      animation: AnimationType.slideUp, // AnimationType (package enum)
      duration: const Duration( milliseconds:  300 ), // Duration
      reverseDuration: const Duration( milliseconds:  300), // Duration
      curve: Curves.easeOut, // bool
      fullscreenDialog: false, // bool
      replacement: false, // bool
    );
  }
}