import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../routes/app_router.dart';
import '../screens/playing_queue_screen.dart';
import '../screens/song_played_screen.dart';
import '../theme/app_theme.dart';
import 'widgets.dart';

class CurrentSongTile extends StatefulWidget {
  const CurrentSongTile({super.key});

  @override
  State<CurrentSongTile> createState() => _CurrentSongTileState();
}

class _CurrentSongTileState extends State<CurrentSongTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _playAnimation;

  @override
  void initState() {
    super.initState();
    _playAnimation = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _playAnimation.forward();
  }

  @override
  void dispose() {
    _playAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 0.5, color: Colors.white12),
        _SongInfoTile(playAnimation: _playAnimation),
        const _ProgressBar(),
      ],
    );
  }
}

// Rebuilds only when the playing song changes.
class _SongInfoTile extends StatelessWidget {
  const _SongInfoTile({required this.playAnimation});

  final AnimationController playAnimation;

  @override
  Widget build(BuildContext context) {
    final songPlayed = context.select((PlaybackStateCubit c) => c.state.songPlayed);
    final appDirectory = context.select((LibraryCubit c) => c.state.appDirectory);
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiCubit = context.read<UICubit>();
    final imageFile = File('$appDirectory/${songPlayed.albumId}.jpg');
    final heroId = 'current-song-${songPlayed.id}';

    return Material(
      color: AppTheme.backgroundBase,
      child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      visualDensity: const VisualDensity(horizontal: -1, vertical: -1),
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

          if (isPlaying) {
            playAnimation.forward();
          } else {
            playAnimation.reverse();
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {
                  if (isPlaying) {
                    playAnimation.reverse();
                    audioPlayer.pause();
                  } else {
                    playAnimation.forward();
                    audioPlayer.play();
                  }
                },
                splashRadius: 24,
                iconSize: 28,
                icon: AnimatedIcon(
                  progress: playAnimation,
                  icon: AnimatedIcons.play_pause,
                  color: Colors.white,
                ),
              ),
              IconButton(
                splashRadius: 24,
                icon: const Icon(Icons.queue_music),
                iconSize: 26,
                color: Colors.white,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlayingQueueScreen()),
                ),
              ),
            ],
          );
        },
      ),
      title: Text(
        songPlayed.title.value(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      subtitle: Text(
        '${songPlayed.artist.valueEmpty('No Artist')} • ${songPlayed.album}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppTheme.lightTextColor),
      ),
      onTap: () {
        uiCubit.updateCurrentHeroId(heroId);
        Navigator.push(
          context,
          AppRouter.slideUpRoute(const SongPlayedScreen()),
        );
      },
    ),
    );
  }
}

// Rebuilds every second (position stream), but is only a 2px-tall Container.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final currentDuration =
        context.select((AudioControlCubit c) => c.state.currentDuration);
    final songDuration =
        context.select((PlaybackStateCubit c) => c.state.songPlayed.duration);

    if (songDuration == null || songDuration == 0) return const SizedBox.shrink();

    final progress = (currentDuration.inMilliseconds / songDuration).clamp(0.0, 1.0);
    return Stack(
      children: [
        Container(height: 3, width: width, color: Colors.white10),
        Container(
          height: 3,
          width: width * progress,
          decoration: const BoxDecoration(
            color: AppTheme.accentColor,
            borderRadius: BorderRadius.horizontal(right: Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}
