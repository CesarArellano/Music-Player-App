import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:music_player_app/providers/music_player_provider.dart';

import '../providers/audio_control_provider.dart';
import '../screens/song_played_screen.dart';

class MusicActions {
  static void songPlayAndPause(BuildContext context, SongModel song) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);

    final path = song.data;
    
    if( musicPlayerProvider.songPlayed.title != song.title ) {
      musicPlayerProvider.audioPlayer.stop();
      musicPlayerProvider.audioPlayer.open(
        Audio.file(path),
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
        showNotification: true,
      );
      musicPlayerProvider.audioPlayer.currentPosition.listen((duration) {
        audioControlProvider.current = duration;
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