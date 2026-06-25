import 'dart:io' show File;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../search/search_delegate.dart';
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
        setState(() => appBarTitle = widget.genreSelected.genre);
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
    final cubit = context.read<MusicPlayerCubit>();
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
    final musicPlayerState = context.watch<MusicPlayerCubit>().state;

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
            onPressed: () =>
                showSearch(context: context, delegate: MusicSearchDelegate()),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ArtworkImage(
                              artworkId: widget.genreSelected.id,
                              type: ArtworkType.GENRE,
                              width: 150,
                              height: 150,
                              size: 600,
                              radius: BorderRadius.circular(4),
                            ),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.genreSelected.genre,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${widget.genreSelected.numOfSongs} ${widget.genreSelected.numOfSongs > 1 ? 'Songs' : 'Song'}',
                                    style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: PlayShuffleButtons(
                          heroId: 'genre-song-',
                          id: widget.genreSelected.id,
                          songList: musicPlayerState
                                  .genreCollection[widget.genreSelected.id] ??
                              [],
                          typePlaylist: PlaylistType.genre,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = musicPlayerState
                          .genreCollection[widget.genreSelected.id]![i];
                      final imageFile = File(
                        '${musicPlayerState.appDirectory}/${song.albumId}.jpg',
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
                    childCount: (musicPlayerState
                                .genreCollection[widget.genreSelected.id] ??
                            [])
                        .length,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: (musicPlayerState.isLoading ||
              musicPlayerState.songPlayed.title.value().isEmpty)
          ? null
          : const CurrentSongTile(),
    );
  }
}
