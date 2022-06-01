import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../providers/music_player_provider.dart';
import '../screens/song_played_screen.dart';
import 'artwork_image.dart';

class CurrentSongTile extends StatefulWidget {
  const CurrentSongTile({
    Key? key,
  }) : super(key: key);

  @override
  State<CurrentSongTile> createState() => _CurrentSongTileState();
}

class _CurrentSongTileState extends State<CurrentSongTile> with SingleTickerProviderStateMixin {

  late AnimationController _playAnimation;

  @override
  void initState() {
    super.initState();
    _playAnimation =  AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _playAnimation.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _playAnimation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
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
                final isPlaying = audioPlayer.isPlaying.value;
                if( isPlaying ) {
                  _playAnimation.reverse();
                  audioPlayer.pause();
                } else {
                  _playAnimation.forward();
                  audioPlayer.play();
                }
              },
              splashRadius: 24,
              icon: AnimatedIcon( 
                progress: _playAnimation,
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