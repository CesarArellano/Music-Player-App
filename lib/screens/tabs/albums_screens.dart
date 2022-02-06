import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/ripple_tile.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../providers/music_player_provider.dart';

class AlbumsScreen extends StatefulWidget {

  const AlbumsScreen({Key? key}) : super(key: key);

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final albumList = musicPlayerProvider.albumList;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator() )
      : Container(
        color: const Color(0xFF144781),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 235,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: albumList.length,
          itemBuilder: ( _, int i ) {
            final album = albumList[i];
            return RippleTile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QueryArtworkWidget(
                    keepOldArtwork: true,
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    format: ArtworkFormat.PNG,
                    artworkBorder: BorderRadius.zero,
                    artworkWidth: 200,
                    artworkHeight: 190,
                    artworkQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(album.album, maxLines: 1, overflow: TextOverflow.ellipsis,),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text("${ album.numOfSongs } ${ (album.numOfSongs > 1) ? 'songs' : 'song' }"),
                  ),
                ],
              ),
              onTap: () {}
            );
          },
    ),
      );
  }
}