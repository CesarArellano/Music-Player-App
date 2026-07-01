import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../services/playback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';


class PlayingQueueScreen extends StatefulWidget {
  const PlayingQueueScreen({super.key});

  @override
  State<PlayingQueueScreen> createState() => _PlayingQueueScreenState();
}

class _PlayingQueueScreenState extends State<PlayingQueueScreen> {
  final ScrollController _scrollController = ScrollController();

  // Heights derived from the sliver layout:
  //   SliverAppBar expandedHeight(120) - kToolbarHeight(56) = 64
  //   SliverToBoxAdapter "Up next" row: top(8) + text(~18) + bottom(8) = 34
  //   Each _QueueTile (ListTile with subtitle + 55px image) = 72
  static const double _appBarScrollRange = 64.0;
  static const double _headerHeight = 34.0;
  static const double _itemHeight = 72.0;

  bool _isScrollTopButtonVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentSong(animated: false));
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final position = _scrollController.position;
    final isVisible = position.pixels > 100 && position.userScrollDirection == ScrollDirection.forward;
    if (_isScrollTopButtonVisible != isVisible) {
      setState(() => _isScrollTopButtonVisible = isVisible);
    }
  }

  Future<void> _scrollToCurrentSong({bool animated = true}) async {
    if (!mounted || !_scrollController.hasClients) return;
    final playbackState = context.read<PlaybackStateCubit>().state;
    final effectiveIndices = audioPlayerHandler<PlaybackService>().effectiveIndices;
    final playlist = playbackState.currentPlaylist;
    final songPlayed = playbackState.songPlayed;

    if (playlist.isEmpty) return;

    int displayIndex = -1;
    for (int i = 0; i < playlist.length; i++) {
      if (playlist[effectiveIndices?[i] ?? i].id == songPlayed.id) {
        displayIndex = i;
        break;
      }
    }

    if (displayIndex <= 0) return;

    final offset = (_appBarScrollRange + _headerHeight + displayIndex * _itemHeight)
        .clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animated) {
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(offset);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final audioControlState = context.watch<AudioControlCubit>().state;
    final libraryState = context.watch<LibraryCubit>().state;
    final playbackService = audioPlayerHandler<PlaybackService>();
    final audioPlayer = audioPlayerHandler<AudioPlayer>();

    final playlist = playbackState.currentPlaylist;
    final effectiveIndices = playbackService.effectiveIndices;
    final currentIndex = audioControlState.currentIndex;
    final songPlayed = playbackState.songPlayed;
    final isShuffling = playbackState.isShuffling;
    final displayPosition = isShuffling && effectiveIndices != null
        ? effectiveIndices.indexOf(currentIndex) + 1
        : currentIndex + 1;

    return Scaffold(
      body: Stack(
        children: [
          Scrollbar(
            controller: _scrollController,
            interactive: true,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceColor,
                  expandedHeight: playlist.isEmpty ? 0 : 120,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.lightTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        color: isShuffling
                            ? AppTheme.accentColor
                            : AppTheme.lightTextColor,
                      ),
                      onPressed: () {
                        playbackService.setShuffleModeEnabled(!isShuffling);
                        context
                            .read<PlaybackStateCubit>()
                            .updateIsShuffling(!isShuffling);
                      },
                    ),
                    StreamBuilder<LoopMode>(
                      stream: audioPlayer.loopModeStream,
                      builder: (context, snapshot) {
                        final loopMode = snapshot.data ?? LoopMode.off;
                        final IconData icon;
                        final Color color;
                        final LoopMode next;
                        switch (loopMode) {
                          case LoopMode.off:
                            icon = Icons.repeat;
                            color = Colors.white54;
                            next = LoopMode.one;
                          case LoopMode.one:
                            icon = Icons.repeat_one;
                            color = AppTheme.accentColor;
                            next = LoopMode.all;
                          case LoopMode.all:
                            icon = Icons.repeat;
                            color = AppTheme.accentColor;
                            next = LoopMode.off;
                        }
                        return IconButton(
                          icon: Icon(icon, color: color),
                          onPressed: () => audioPlayer.setLoopMode(next),
                        );
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert,
                          color: AppTheme.lightTextColor),
                      onSelected: (value) {
                        if (value == 'clear') {
                          context
                              .read<PlaybackStateCubit>()
                              .updateCurrentPlaylist([]);
                          context
                              .read<PlaybackStateCubit>()
                              .clearSongPlayed();
                          context
                              .read<AudioControlCubit>()
                              .updateCurrentIndex(-1);
                          audioPlayerHandler<AudioPlayer>().stop();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'clear', child: Text('Clear queue')),
                      ],
                    ),
                  ],
                  flexibleSpace: const FlexibleSpaceBar(
                    title: Text('Playing queue',
                        style:
                            TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    titlePadding: EdgeInsets.only(left: 50, bottom: 12),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                    child: Text(
                      'Up next  •  $displayPosition/${playlist.length}  •  ${playlist.totalDurationString()}',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
                SliverReorderableList(
                  itemCount: playlist.length,
                  onReorderItem: (oldIndex, newIndex) =>
                      playbackService.moveInQueue(oldIndex, newIndex),
                  itemBuilder: (context, i) {
                    final song = playlist[effectiveIndices?[i] ?? i];
                    final imageFile = File(
                      '${libraryState.appDirectory}/${song.albumId}.jpg',
                    );
                    final heroId = 'queue-${song.id}';
                    final isPlaying = songPlayed.id == song.id;
          
                    return _QueueTile(
                      key: ValueKey(song.id),
                      song: song,
                      index: i,
                      imageFile: imageFile,
                      heroId: heroId,
                      isPlaying: isPlaying,
                      dragEnabled: !isShuffling,
                      onRemove: () => playbackService.removeFromQueue(song),
                      onTap: () {
                        audioPlayer.seek(Duration.zero,
                            index: effectiveIndices?[i] ?? i);
                        audioPlayer.play();
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          ScrollToTopButton(
            isVisible: _isScrollTopButtonVisible,
            onPressed: () => _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
      bottomNavigationBar: songPlayed.id == 0
          ? null
          : CurrentSongTile(onQueueTap: _scrollToCurrentSong),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    super.key,
    required this.song,
    required this.index,
    required this.imageFile,
    required this.heroId,
    required this.isPlaying,
    required this.dragEnabled,
    required this.onRemove,
    required this.onTap,
  });

  final SongModel song;
  final int index;
  final File imageFile;
  final String heroId;
  final bool isPlaying;
  final bool dragEnabled;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = isPlaying ? AppTheme.accentColor : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Row(
      children: [
        if (dragEnabled)
          ReorderableDelayedDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.drag_handle, color: Colors.white54),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.drag_handle, color: Colors.white12),
          ),
        Expanded(
          child: ListTile(
            leading: ArtworkFileImage(
              artworkId: song.id,
              imageFile: imageFile,
              height: 55,
              width: 55,
              tag: heroId,
            ),
            title: Text(
              song.title.value(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: titleColor),
            ),
            subtitle: Text(
              '${song.duration.toDurationString()} • ${song.artist.valueEmpty('No Artist')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.lightTextColor, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppTheme.lightTextColor),
                  onPressed: onRemove,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: AppTheme.lightTextColor),
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    builder: (_) => MoreSongOptionsModal(song: song),
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ],
      ),
    );
  }
}
