import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../helpers/music_actions.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../screens/song_played_screen.dart';
import '../theme/app_theme.dart';
import 'artwork_image.dart';
import 'widgets.dart';

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
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SelectorSongTitle(playAnimation: _playAnimation),
        const CustomBottomNavigationBar()
      ],
    );
  }
}

class _SelectorSongTitle extends StatelessWidget {
  const _SelectorSongTitle({
    Key? key,
    required AnimationController playAnimation,
  }) : _playAnimation = playAnimation, super(key: key);

  final AnimationController _playAnimation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0.25, color: AppTheme.primaryColor),
        ListTile(
          tileColor: const Color(0xFF001F42),
          leading: ArtworkImage(
            artworkId: songPlayed.id,
            type: ArtworkType.AUDIO,
            height: 40,
            width: 40,
            size: 200,
            radius: BorderRadius.circular(2.5),
          ),
          trailing: StreamBuilder<bool>(
            stream: audioPlayer.isPlaying,
            builder: (context, snapshot) {
              final isPlaying = snapshot.data ?? false;
              
              if( isPlaying ) {
                _playAnimation.forward();
              } else {
                _playAnimation.reverse();
              }
              
              return Row(
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
                  ),
                  IconButton(
                    splashRadius: 24,
                    icon: const Icon(Icons.queue_music),
                    color: AppTheme.accentColor,
                    onPressed: () => MusicActions.showCurrentPlayList(context),
                  )
                ],
              );
            }
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
        Container(
          alignment: AlignmentDirectional.topStart,
          height: 1,
          width: width * (audioControlProvider.currentDuration.inMilliseconds / songPlayed.duration! ),
          color: AppTheme.accentColor,
        )
      ],
    );
  }
}