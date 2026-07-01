import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../models/artist_content_model.dart';
import '../models/playlist_type.dart';
import '../routes/app_router.dart';
import '../services/music_orchestrator_service.dart';
import 'song_played_screen.dart';
import 'music_search_screen.dart';
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
  
  // artwork (175) + bottom padding (16) — title appears exactly when header is gone
  static const double _headerHeight = 191.0;
  
  bool _collapsed = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _getSongs();
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

  Future<void> _getSongs() async {
    final cubit = context.read<LibraryCubit>();
    final artistSongs =
        cubit.state.artistCollection[widget.artistSelected.id]?.songs.length ??
            0;
    await cubit.searchByArtistId(
      widget.artistSelected.id,
      force: artistSongs != widget.artistSelected.numberOfTracks,
    );
    if (mounted) setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final artistContentModel =
        libraryState.artistCollection[widget.artistSelected.id] ??
            ArtistContentModel();
    final albums = widget.artistSelected.numberOfAlbums ?? 1;
    final tracks = widget.artistSelected.numberOfTracks ?? 1;

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
                    icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _collapsed ? 1.0 : 0.0,
                    child: Text(
                      widget.artistSelected.artist,
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
                SliverToBoxAdapter(
                  child: CollectionHeader(
                    artworkId: widget.artistSelected.id,
                    imageFile: File(
                      '${libraryState.appDirectory}/${artistContentModel.songs.first.albumId}.jpg',
                    ),
                    artworkType: ArtworkType.ARTIST,
                    title: widget.artistSelected.artist,
                    subtitle1:
                        '$albums ${albums > 1 ? 'Albums' : 'Album'} • $tracks ${tracks > 1 ? 'Songs' : 'Song'}',
                    subtitle2: artistContentModel.totalDuration,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyHeaderDelegate(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
                      child: PlayShuffleButtons(
                        heroId: 'artist-song-',
                        id: widget.artistSelected.id,
                        songList: artistContentModel.songs,
                        typePlaylist: PlaylistType.artist,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, top: 15),
                        child: Text('Albums', style: TextStyle(fontSize: 16)),
                      ),
                      _AlbumList(
                        artistContentModel: artistContentModel,
                        appDirectory: libraryState.appDirectory,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16.0, bottom: 5),
                        child: Text('Songs', style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                _SongList(
                  artistContentModel: artistContentModel,
                  libraryState: libraryState,
                  widget: widget,
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

class _SongList extends StatelessWidget {
  const _SongList({
    required this.artistContentModel,
    required this.libraryState,
    required this.widget,
  });

  final ArtistContentModel artistContentModel;
  final LibraryState libraryState;
  final ArtistSelectedScreen widget;

  @override
  Widget build(BuildContext context) {
    return SliverList(
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
            onTap: () {
              audioPlayerHandler<MusicOrchestratorService>().playSong(
                song,
                PlaylistType.artist,
                id: widget.artistSelected.id,
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
        childCount: artistContentModel.songs.length,
      ),
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
