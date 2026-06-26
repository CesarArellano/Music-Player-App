import 'dart:io' show File;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../models/artist_content_model.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'album_selected_screen.dart';

class ArtistSelectedScreen extends StatefulWidget {
  const ArtistSelectedScreen({super.key, required this.artistSelected});

  final ArtistModel artistSelected;

  @override
  State<ArtistSelectedScreen> createState() => _ArtistSelectedScreenState();
}

class _ArtistSelectedScreenState extends State<ArtistSelectedScreen> {
  final ScrollController _scrollController = ScrollController();
  String? appBarTitle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels < 40 && appBarTitle != null) {
        setState(() => appBarTitle = null);
      }
      if (_scrollController.position.pixels >= 40 && appBarTitle == null) {
        setState(() => appBarTitle = widget.artistSelected.artist);
      }
    });
    _getSongs();
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {});
    _scrollController.dispose();
    super.dispose();
  }

  void _getSongs() {
    final cubit = context.read<LibraryCubit>();
    final artistSongs =
        cubit.state.artistCollection[widget.artistSelected.id]?.songs.length ??
            0;
    cubit.searchByArtistId(
      widget.artistSelected.id,
      force: artistSongs != widget.artistSelected.numberOfTracks,
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final artistContentModel =
        libraryState.artistCollection[widget.artistSelected.id] ??
            ArtistContentModel();

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
            icon: const Icon(Icons.search),
            color: AppTheme.lightTextColor,
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
                      _AlbumHeader(
                        artistSelected: widget.artistSelected,
                        artistContentModel: artistContentModel,
                        artistImageFile: File(
                          '${libraryState.appDirectory}/${artistContentModel.songs.first.albumId}.jpg',
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 15.0),
                        child: PlayShuffleButtons(
                          heroId: 'artist-song-',
                          id: widget.artistSelected.id,
                          songList: artistContentModel.songs,
                          typePlaylist: PlaylistType.artist,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 15.0, top: 15),
                        child: Text('Albums', style: TextStyle(fontSize: 16)),
                      ),
                      _AlbumList(
                        artistContentModel: artistContentModel,
                        appDirectory: libraryState.appDirectory,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 15.0, bottom: 5),
                        child: Text('Songs', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final song = artistContentModel.songs[i];
                      final imageFile = File(
                        '${libraryState.appDirectory}/${song.albumId}.jpg',
                      );
                      final heroId = 'artist-song-${song.id}';

                      return RippleTile(
                        child: CustomListTile(
                          imageFile: imageFile,
                          title: song.title.value(),
                          subtitle: song.artist.valueEmpty('No Artist'),
                          artworkId: song.id,
                          tag: heroId,
                        ),
                        onTap: () => MusicActions.songPlayAndPause(
                          context,
                          song,
                          PlaylistType.artist,
                          id: widget.artistSelected.id,
                          heroId: heroId,
                        ),
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => MoreSongOptionsModal(song: song),
                        ),
                      );
                    },
                    childCount: artistContentModel.songs.length,
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

class _AlbumList extends StatelessWidget {
  const _AlbumList({
    required this.artistContentModel,
    required this.appDirectory,
  });

  final ArtistContentModel artistContentModel;
  final String appDirectory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artistContentModel.albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: 5),
        itemBuilder: (context, i) {
          final album = artistContentModel.albums[i];

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i == 0) const SizedBox(width: 15),
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RippleTile(
                      borderRadius: BorderRadius.circular(5),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AlbumSelectedScreen(albumSelected: album),
                        ),
                      ),
                      child: ArtworkFileImage(
                        artworkId: album.id,
                        height: 130,
                        width: 130,
                        imageFile: File('$appDirectory/${album.id}.jpg'),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      album.album,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w400),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
              if (i == artistContentModel.albums.length - 1)
                const SizedBox(width: 15),
            ],
          );
        },
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.artistSelected,
    required this.artistContentModel,
    required this.artistImageFile,
  });

  final ArtistModel artistSelected;
  final ArtistContentModel artistContentModel;
  final File artistImageFile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtworkFileImage(
            artworkId: artistSelected.id,
            imageFile: artistImageFile,
            artworkType: ArtworkType.ARTIST,
            width: 175,
            height: 175,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artistSelected.artist,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '${artistSelected.numberOfAlbums} ${(artistSelected.numberOfAlbums ?? 1) > 1 ? 'Albums' : 'Album'} • ${artistSelected.numberOfTracks} ${((artistSelected.numberOfTracks ?? 1) > 1) ? 'Songs' : 'Song'}',
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 10),
                Text(
                  artistContentModel.totalDuration,
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
    );
  }
}
