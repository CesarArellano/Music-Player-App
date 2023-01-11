import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../widgets/artwork_image.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if( _scrollController.position.pixels >= 70 ) {
        appBarTitle = widget.artistSelected.artist;
      } else {
        appBarTitle = null;
      }
      setState(() {});
    });
    getSongs();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void getSongs() {
    Provider.of<MusicPlayerProvider>(context, listen: false).searchByArtistId( widget.artistSelected.id );
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
          : FadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Text(appBarTitle!, maxLines: 1, overflow: TextOverflow.ellipsis)
          ),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            color: AppTheme.lightTextColor,
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
        bottom: _BottomAppBar(),
      ),
      body: musicPlayerProvider.isLoading
        ? const Center( child: CircularProgressIndicator(color: Colors.white) )
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
              itemCount: musicPlayerProvider.artistCollection[widget.artistSelected.id]!.length,
              itemBuilder: (_, int i) {
                final song = musicPlayerProvider.artistCollection[widget.artistSelected.id]![i];
                final imageFile = File(MusicActions.getArtworkPath(song.data) ?? '');
                
                return RippleTile(
                  child: ListTile(
                    leading: imageFile.existsSync()
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(2.5),
                        child: Image.file(
                          imageFile,
                          width: 50,
                          height: 50,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.low,
                        ),
                      )
                      : ArtworkImage(
                        artworkId: song.albumId ?? 1,
                        type: ArtworkType.ALBUM,
                        width: 50,
                        height: 50,
                        size: 250,
                        radius: BorderRadius.circular(2.5),
                      ),
                    title: Text(song.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artist ?? 'No Artist', style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12))
                  ),
                  onTap: () {
                    MusicActions.songPlayAndPause(context, song, TypePlaylist.artist, id: widget.artistSelected.id );
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

class _BottomAppBar extends StatelessWidget implements PreferredSizeWidget {

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(); // Your custom widget implementation.
  }

}