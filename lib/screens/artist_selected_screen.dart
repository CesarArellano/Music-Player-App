import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../widgets/widgets.dart';

class ArtistSelectedScreen extends StatefulWidget {
  const ArtistSelectedScreen({
    Key? key,
    required this.artistSelected
  }) : super(key: key);

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
      if( _scrollController.position.pixels >= 70 && appBarTitle == null ) {
        setState(() => appBarTitle = widget.artistSelected.artist);
      }
    });
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(() { });
    _scrollController.dispose();
  }

  void getSongs() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<MusicPlayerProvider>(context, listen: false).searchByArtistId( widget.artistSelected.id );
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ), 
        title: appBarTitle == null 
          ? null
          : Text(appBarTitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            color: AppTheme.lightTextColor,
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
      ),
      body: isLoading
        ? const Center( child: CircularProgressIndicator() )
        : ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: 
                [
                  ArtworkImage(
                    artworkId: widget.artistSelected.id,
                    type: ArtworkType.ARTIST,
                    width: 150,
                    height: 150,
                    size: 500,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.artistSelected.artist,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "${ widget.artistSelected.numberOfAlbums } ${ (widget.artistSelected.numberOfAlbums ?? 1 ) > 1 ? 'Albums' : 'Album'} • ${ widget.artistSelected.numberOfTracks } ${ ((widget.artistSelected.numberOfTracks ?? 1 ) > 1) ? 'Songs' : 'Song' }",
                          style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w400)
                        ),
                      ],
                    ),
                  )
                ]
              ),
            ),
            const Divider(color: Colors.white54, height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ( musicPlayerProvider.artistCollection[widget.artistSelected.id] ?? [] ).length,
              itemBuilder: (_, int i) {
                final song = musicPlayerProvider.artistCollection[widget.artistSelected.id]![i];
                final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
                final heroId = 'artist-song-${ song.id }';

                return RippleTile(
                  child: CustomListTile(
                    imageFile: imageFile,
                    title: song.title ?? '',
                    subtitle: song.artist ?? 'No Artist',
                    artworkId: song.id,
                    tag: heroId,
                  ),
                  onTap: () {
                    MusicActions.songPlayAndPause(context, song, TypePlaylist.artist, id: widget.artistSelected.id, heroId: heroId);
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder:( _ ) => MoreSongOptionsModal(song: song)
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 5),
          ],
        ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title ?? '').isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}