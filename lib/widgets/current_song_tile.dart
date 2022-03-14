import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/screens/song_played_screen.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import 'package:provider/provider.dart';

import '../providers/music_player_provider.dart';

class CurrentSongTile extends StatelessWidget {
  const CurrentSongTile({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF204C70)))
      ),
      child: ListTile(
        tileColor: const Color(0xFF0E3158),
        leading: ArtworkImage(
          artworkId: songPlayed.id,
          type: ArtworkType.AUDIO,
          height: 40,
          width: 40,
          size: 200,
          radius: BorderRadius.circular(2.5),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final isPlaying = musicPlayerProvider.audioPlayer.isPlaying.value;
                if( isPlaying ) {
                  playAnimation?.reverse();
                  musicPlayerProvider.audioPlayer.pause();
                } else {
                  playAnimation?.forward();
                  musicPlayerProvider.audioPlayer.play();
                }
              },
              splashRadius: 24,
              icon: AnimatedIcon( 
                progress: playAnimation!,
                icon: AnimatedIcons.play_pause,
                color: Colors.amber,
              )
            )
          ],
        ),
        title: Text(
          songPlayed.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
        ),
        subtitle: Text(
          "${ songPlayed.artist ?? 'No artist' } • ${ songPlayed.album }",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)
        ),
        onTap: () {
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
        },
      ),
    );
  }
}