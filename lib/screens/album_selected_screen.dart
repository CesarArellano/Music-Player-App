import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import 'music_search_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AlbumSelectedScreen extends StatefulWidget {
  const AlbumSelectedScreen({super.key, required this.albumSelected});

  final AlbumModel albumSelected;

  @override
  State<AlbumSelectedScreen> createState() => _AlbumSelectedScreenState();
}

class _AlbumSelectedScreenState extends State<AlbumSelectedScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _collapsed = false;
  bool isLoading = true;

  // artwork (175) + bottom padding (16) — title appears exactly when header is gone
  static const double _headerHeight = 191.0;

  @override
  void initState() {
    super.initState();
    _getSongs();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldCollapse = _scrollController.position.pixels >= _headerHeight;
    if (shouldCollapse != _collapsed) setState(() => _collapsed = shouldCollapse);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _getSongs() {
    final cubit = context.read<LibraryCubit>();
    final albumsLength =
        cubit.state.albumCollection[widget.albumSelected.id]?.length ?? 0;
    cubit.searchByAlbumId(
      widget.albumSelected.id,
      force: albumsLength != widget.albumSelected.numOfSongs,
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final imageGeneralFile = File(
      '${libraryState.appDirectory}/${widget.albumSelected.id}.jpg',
    );

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _collapsed ? 1.0 : 0.0,
              child: Text(
                widget.albumSelected.album,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions: <Widget>[
              IconButton(
                splashRadius: 20,
                icon: const Icon(Icons.search, color: AppTheme.lightTextColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MusicSearchScreen()),
                ),
              ),
            ],
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: _AlbumHeader(
                albumSelected: widget.albumSelected,
                imageFile: imageGeneralFile,
                songs: libraryState.albumCollection[widget.albumSelected.id] ?? [],
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyButtonsDelegate(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 6),
                  child: PlayShuffleButtons(
                    heroId: 'album-song-',
                    id: widget.albumSelected.id,
                    songList: libraryState.albumCollection[widget.albumSelected.id] ?? [],
                    typePlaylist: PlaylistType.album,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = libraryState
                      .albumCollection[widget.albumSelected.id]![i];
                  final imageFile = File(
                    '${libraryState.appDirectory}/${song.albumId}.jpg',
                  );
                  final heroId = 'album-song-${song.id}';

                  return RippleTile(
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          Text('${i + 1}'),
                          SizedBox(width: (i + 1 >= 10) ? 18 : 25),
                          ArtworkFileImage(
                            artworkId: widget.albumSelected.id,
                            artworkType: ArtworkType.ALBUM,
                            imageFile: imageFile,
                            tag: heroId,
                          ),
                        ],
                      ),
                      title: Text(song.title.value(),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        song.artist.valueEmpty('No Artist'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.lightTextColor, fontSize: 12),
                      ),
                    ),
                    onTap: () => MusicActions.songPlayAndPause(
                      context,
                      song,
                      PlaylistType.album,
                      id: widget.albumSelected.id,
                      heroId: heroId,
                    ),
                    onLongPress: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => MoreSongOptionsModal(song: song),
                    ),
                  );
                },
                childCount: (libraryState
                            .albumCollection[widget.albumSelected.id] ??
                        [])
                    .length,
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: (libraryState.isLoading ||
              playbackState.songPlayed.title.value().isEmpty)
          ? null
          : const CurrentSongTile(),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.albumSelected,
    required this.imageFile,
    required this.songs,
  });

  final AlbumModel albumSelected;
  final File imageFile;
  final List<SongModel> songs;

  String get _totalDuration {
    final totalMs = songs.fold<int>(0, (sum, s) => sum + (s.duration ?? 0));
    final totalSec = totalMs ~/ 1000;
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final n = albumSelected.numOfSongs;
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtworkFileImage(
            artworkId: albumSelected.id,
            artworkType: ArtworkType.ALBUM,
            imageFile: imageFile,
            width: 175,
            height: 175,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  albumSelected.album,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w400, height: 0),
                ),
                const SizedBox(height: 4),
                Text(
                  albumSelected.artist.valueEmpty('No Artist'),
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Text(
                  '${albumSelected.getMap['minyear']} • $n ${n > 1 ? 'Songs' : 'Song'} • $_totalDuration',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyButtonsDelegate extends SliverPersistentHeaderDelegate {
  const _StickyButtonsDelegate({required this.child});

  final Widget child;

  static const double height = 57.0;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyButtonsDelegate old) => child != old.child;
}
