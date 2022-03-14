import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/screens/screens.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
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
      : albumList.isNotEmpty
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
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
                  ArtworkImage(
                    artworkId: album.id,
                    type: ArtworkType.ALBUM,
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
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (_) => AlbumSelectedScreen( albumSelected: album) ));
              }
            );
          },
      ),
        )
      : const Center( 
        child: Text('No Albums', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
      );
  }
}