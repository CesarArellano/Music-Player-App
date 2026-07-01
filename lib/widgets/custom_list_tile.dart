import 'dart:io' show File;
import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_music_player/cubits/cubits.dart';
import 'package:focus_music_player/widgets/artwork_file_image.dart';
import 'package:music_query_selector/music_query_selector.dart' show ArtworkType;

import '../theme/app_theme.dart';

class CustomListTile extends StatefulWidget {
  
  const CustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkId,
    this.artworkType = ArtworkType.AUDIO,
    this.imageFile,
    this.trailing,
    this.tag = ''
  });
  
  final int artworkId;
  final ArtworkType artworkType;
  final String title;
  final String subtitle;
  final File? imageFile;
  final Widget? trailing;
  final String tag;

  @override
  State<CustomListTile> createState() => _CustomListTileState();
}

class _CustomListTileState extends State<CustomListTile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    final state = context.read<PlaybackStateCubit>().state;
    _syncAnimation(
      isActive: state.songPlayed.id == widget.artworkId,
      isPlaying: state.isPlaying,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _syncAnimation({required bool isActive, required bool isPlaying}) {
    if (isActive && isPlaying) {
      if (!_animationController.isAnimating) {
        _animationController.repeat();
      }
    } else if (isActive) {
      _animationController.stop();
    } else {
      _animationController
        ..stop()
        ..reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaybackStateCubit, PlaybackState>(
      listenWhen: (prev, curr) =>
          (prev.songPlayed.id == widget.artworkId) !=
              (curr.songPlayed.id == widget.artworkId) ||
          prev.isPlaying != curr.isPlaying,
      listener: (context, state) => _syncAnimation(
        isActive: state.songPlayed.id == widget.artworkId,
        isPlaying: state.isPlaying,
      ),
      buildWhen: (prev, curr) =>
          (prev.songPlayed.id == widget.artworkId) !=
          (curr.songPlayed.id == widget.artworkId),
      builder: (context, state) {
        final isActive = state.songPlayed.id == widget.artworkId;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isActive ? AppTheme.accentColor : AppTheme.white,
              fontWeight: FontWeight.w400,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            widget.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
          ),
          leading: Stack(
            children: [
              ArtworkFileImage(
                artworkId: widget.artworkId,
                artworkType: widget.artworkType,
                imageFile: widget.imageFile,
                tag: widget.tag,
              ),
              if (isActive) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: _EqualizerBars(
                      animation: _animationController,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: widget.trailing,
        );
      },
    );
  }
}

class _EqualizerBars extends StatelessWidget {
  const _EqualizerBars({required this.animation, required this.color});

  final Animation<double> animation;
  final Color color;

  static const _minH = 3.0;
  static const _maxH = 14.0;

  double _height(double progress, double phase) {
    final raw = sin((progress + phase) * 2 * pi);
    return _minH + (raw + 1) / 2 * (_maxH - _minH);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) {
        final p = animation.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Bar(height: _height(p, 0.0), color: color),
            const SizedBox(width: 2),
            _Bar(height: _height(p, 1 / 3), color: color),
            const SizedBox(width: 2),
            _Bar(height: _height(p, 2 / 3), color: color),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}