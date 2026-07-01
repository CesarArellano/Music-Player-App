import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../models/playlist_type.dart';
import '../routes/app_router.dart';
import '../services/music_orchestrator_service.dart';
import 'music_search_screen.dart';
import 'song_played_screen.dart';
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
    final songs = libraryState.albumCollection[widget.albumSelected.id] ?? [];
    final n = widget.albumSelected.numOfSongs;

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
              child: CollectionHeader(
                artworkId: widget.albumSelected.id,
                imageFile: imageGeneralFile,
                title: widget.albumSelected.album,
                subtitle1: widget.albumSelected.artist.valueEmpty('No Artist'),
                subtitle2:
                    '${widget.albumSelected.getMap['minyear']} • $n ${n > 1 ? 'Songs' : 'Song'} • ${songs.totalDurationString()}',
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: StickyHeaderDelegate(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 6),
                  child: PlayShuffleButtons(
                    heroId: 'album-song-',
                    id: widget.albumSelected.id,
                    songList: songs,
                    typePlaylist: PlaylistType.album,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final song = songs[i];
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
                    onTap: () {
                      audioPlayerHandler<MusicOrchestratorService>().playSong(
                        song,
                        PlaylistType.album,
                        id: widget.albumSelected.id,
                        heroId: heroId,
                      );
                      Navigator.push(context, AppRouter.slideUpRoute(const SongPlayedScreen()));
                    },
                    onLongPress: () => showModalBottomSheet(
                      context: context,
                      builder: (_) => MoreSongOptionsModal(song: song),
                    ),
                  );
                },
                childCount: songs.length,
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
