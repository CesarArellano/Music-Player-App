import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../screens/song_played_screen.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

class CurrentSongTile extends StatefulWidget {
  const CurrentSongTile({
    Key? key,
    // this.showBottomBar = false
  }) : super(key: key);

  // final bool showBottomBar;
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
    return _SelectorSongTitle(playAnimation: _playAnimation);
  }
}

// return Column(
//   mainAxisAlignment: MainAxisAlignment.end,
//   mainAxisSize: MainAxisSize.min,
//   children: [
//     _SelectorSongTitle(playAnimation: _playAnimation),
//     if( widget.showBottomBar )
//       const CustomBottomNavigationBar()
//   ],
// );

class _SelectorSongTitle extends StatelessWidget {
  const _SelectorSongTitle({
    Key? key,
    required AnimationController playAnimation,
  }) : _playAnimation = playAnimation, super(key: key);

  final AnimationController _playAnimation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final uiProvider = Provider.of<UIProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final heroId = 'current-song-${ songPlayed.id }';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0.20, color: Colors.white30),
        ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
          tileColor: AppTheme.primaryColor,
          leading: ArtworkFileImage(
            artworkId: songPlayed.id,
            imageFile: imageFile,
            height: 40,
            width: 40,
            tag: heroId,
          ),
          trailing: StreamBuilder<bool>(
            stream: audioPlayer.playingStream,
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
                      if( isPlaying ) {
                        _playAnimation.reverse();
                        audioPlayer.pause();
                      } else {
                        _playAnimation.forward();
                        audioPlayer.play();
                      }
                    },
                    splashRadius: 24,
                    iconSize: 28,
                    icon: AnimatedIcon( 
                      progress: _playAnimation,
                      icon: AnimatedIcons.play_pause,
                      color: Colors.white,
                    )
                  ),
                  IconButton(
                    splashRadius: 24,
                    icon: const Icon(Icons.queue_music),
                    iconSize: 26,
                    color: Colors.white,
                    onPressed: () => MusicActions.showCurrentPlayList(context),
                  )
                ],
              );
            }
          ),
          title: Text(
            songPlayed.title.value(), 
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)
          ),
          subtitle: Text(
            "${ songPlayed.artist.valueEmpty('No Artist')} • ${ songPlayed.album }",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor)
          ),
          onTap: () {
            uiProvider.currentHeroId = heroId;
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SongPlayedScreen())
            );
          },
        ),
        Container(
          height: 2,
          width: width * (audioControlProvider.currentDuration.inMilliseconds / songPlayed.duration! ),
          color: AppTheme.accentColor,
        )
      ],
    );
  }
}