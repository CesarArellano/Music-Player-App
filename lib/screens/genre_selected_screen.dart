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

class GenreSelectedScreen extends StatefulWidget {
  const GenreSelectedScreen({super.key, required this.genreSelected});

  final GenreModel genreSelected;

  @override
  State<GenreSelectedScreen> createState() => _GenreSelectedScreenState();
}

class _GenreSelectedScreenState extends State<GenreSelectedScreen> {
  final ScrollController _scrollController = ScrollController();
  // artwork (150) + bottom padding (16) — title appears exactly when header is gone
  static const double _headerHeight = 166.0;
  bool _collapsed = false;
  bool isLoading = true;

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cubit.searchByGenreId(
        widget.genreSelected.id,
        force: (cubit.state.genreCollection[widget.genreSelected.id]?.length ??
                0) !=
            widget.genreSelected.numOfSongs,
      );
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final songPlayed = context.watch<PlaybackStateCubit>().state.songPlayed;
    final songs = libraryState.genreCollection[widget.genreSelected.id] ?? [];

    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: AppTheme.surfaceColor,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: AppTheme.lightTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _collapsed ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: Text(
                      widget.genreSelected.genre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  actions: <Widget>[
                    IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.search,
                          color: AppTheme.lightTextColor),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MusicSearchScreen()),
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: CollectionHeader(
                    artworkId: widget.genreSelected.id,
                    imageFile: File(
                      '${libraryState.appDirectory}/${widget.genreSelected.id}.jpg',
                    ),
                    artworkType: ArtworkType.GENRE,
                    title: widget.genreSelected.genre,
                    subtitle1:
                        '${widget.genreSelected.numOfSongs} ${widget.genreSelected.numOfSongs > 1 ? 'Songs' : 'Song'}',
                    subtitle2: '',
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                      child: PlayShuffleButtons(
                        heroId: 'genre-song-',
                        id: widget.genreSelected.id,
                        songList: songs,
                        typePlaylist: PlaylistType.genre,
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
                      final heroId = 'genre-song-${song.id}';

                      return RippleTile(
                        child: CustomListTile(
                          imageFile: imageFile,
                          title: song.title.value('$i'),
                          subtitle: song.artist.valueEmpty('No Artist'),
                          artworkId: song.id,
                          tag: heroId,
                        ),
                        onTap: () => MusicActions.songPlayAndPause(
                          context,
                          song,
                          PlaylistType.genre,
                          id: widget.genreSelected.id,
                          heroId: heroId,
                        ),
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => MoreSongOptionsModal(
                            song: song,
                            disabledDeleteButton: true,
                          ),
                        ),
                      );
                    },
                    childCount: songs.length,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: (libraryState.isLoading || songPlayed.id == 0)
          ? null
          : const CurrentSongTile(),
    );
  }
}
