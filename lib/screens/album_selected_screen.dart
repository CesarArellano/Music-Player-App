import 'dart:io' show File;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AlbumSelectedScreen extends StatefulWidget {
  const AlbumSelectedScreen({
    Key? key,
    required this.albumSelected
  }) : super(key: key);

  final AlbumModel albumSelected;

  @override
  State<AlbumSelectedScreen> createState() => _AlbumSelectedScreenState();
}

class _AlbumSelectedScreenState extends State<AlbumSelectedScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  void getSongs() {
    final musicPlayerProvider = context.read<MusicPlayerProvider>();
    final albumsLength = musicPlayerProvider.albumCollection[widget.albumSelected.id]?.length ?? 0;
    musicPlayerProvider.searchByAlbumId( 
      widget.albumSelected.id,
      force: albumsLength != widget.albumSelected.numOfSongs
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final imageGeneralFile = File('${ musicPlayerProvider.appDirectory }/${ widget.albumSelected.id }.jpg');
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: isLoading
        ? const Center( child: CircularProgressIndicator() )
        : CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              pinned: true,
              actions: <Widget>[
                IconButton(
                  splashRadius: 20,
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
                ),
              ],
              expandedHeight: size.height * 0.4,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.all(0),
                title: FadeIn(
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 16, left: 5, right: 5),
                    alignment: Alignment.bottomCenter,
                    color: AppTheme.primaryColor.withOpacity(0.35),
                    child: Text(
                      widget.albumSelected.album,
                      style: const TextStyle(fontSize: 18),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis
                    ),
                  ),
                ),
                background: ArtworkFileImage(
                    tag: 'album-screen-${ widget.albumSelected.id }',
                    artworkId: widget.albumSelected.id,
                    artworkType: ArtworkType.ALBUM,
                    width: double.maxFinite,
                    height: 190,
                    imageFile: imageGeneralFile,
                  ),
              )
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(left:15, right: 15, top: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${ widget.albumSelected.numOfSongs } ${ (widget.albumSelected.numOfSongs > 1) ? 'songs' : 'song' }",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor)
                    ),
                    Text(
                      "${ widget.albumSelected.getMap['minyear'] }",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor)
                    ),
                    
                  ],
                ),
              )
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(15),
                child: PlayShuffleButtons(
                  heroId: 'album-song-',
                  id: widget.albumSelected.id,
                  songList: ( musicPlayerProvider.albumCollection[widget.albumSelected.id] ?? [] ),
                  typePlaylist: PlaylistType.album,
                ),
              ),
            ),
            
            SliverList(delegate: SliverChildBuilderDelegate((context, i) {
                final song = musicPlayerProvider.albumCollection[widget.albumSelected.id]![i];
                final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
                final heroId = 'album-song-${ song.id }';
                return RippleTile(
                  child: ListTile(
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 5),
                        Text('${ i + 1 }', style: const TextStyle(fontSize: 13),),
                        SizedBox(width: ( i + 1 >= 10) ? 18 : 25 ),
                        ArtworkFileImage(
                          artworkId: widget.albumSelected.id,
                          artworkType: ArtworkType.ALBUM,
                          imageFile: imageFile,
                          tag: heroId,
                        ),
                      ],
                    ),
                    title: Text(song.title.value(), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist.valueEmpty('No Artist'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12)),
                  ),
                  onTap: () => MusicActions.songPlayAndPause(context, song, PlaylistType.album, id: widget.albumSelected.id, heroId: heroId),
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder:( _ ) => MoreSongOptionsModal(song: song)
                    );
                  },
                );
              },
              childCount: ( musicPlayerProvider.albumCollection[widget.albumSelected.id] ?? [] ).length,
            ))
          ]
        ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || musicPlayerProvider.songPlayed.title.value().isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}