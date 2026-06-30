import 'dart:io' show File;

import 'package:animate_do/animate_do.dart';
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
  String? appBarTitle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getSongs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels < 40 && appBarTitle != null) {
        setState(() => appBarTitle = null);
      }
      if (_scrollController.position.pixels >= 40 && appBarTitle == null) {
        setState(() => appBarTitle = widget.albumSelected.album);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {});
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: appBarTitle == null
            ? null
            : FadeInUp(
                duration: const Duration(milliseconds: 350),
                child: Text(appBarTitle!,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _AlbumHeader(
                        albumSelected: widget.albumSelected,
                        imageFile: imageGeneralFile,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Column(
                          children: [
                            PlayShuffleButtons(
                              heroId: 'album-song-',
                              id: widget.albumSelected.id,
                              songList: libraryState
                                      .albumCollection[widget.albumSelected.id] ??
                                  [],
                              typePlaylist: PlaylistType.album,
                            ),
                            const SizedBox(height: 5),
                          ],
                        ),
                      ),
                    ],
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
  });

  final AlbumModel albumSelected;
  final File imageFile;

  @override
  Widget build(BuildContext context) {
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
                  '${albumSelected.getMap['minyear']} • ${albumSelected.numOfSongs} ${albumSelected.numOfSongs > 1 ? 'songs' : 'song'}',
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
