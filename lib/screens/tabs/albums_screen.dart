import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:focus_music_player/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../providers/music_player_provider.dart';
import '../../widgets/widgets.dart';
import '../screens.dart';

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
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    final albumList = musicPlayerProvider.albumList;

    if( musicPlayerProvider.isLoading ) {
      return const CustomLoader( isGridView: true );
    }

    if( albumList.isEmpty ) {
      return const Center( 
        child: Text(
          'No Albums',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold
          )
        )
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8),
      child: OrientationBuilder(
        builder: (_, orientation ) => GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: orientation == Orientation.landscape ? 4 : 2,
            mainAxisExtent: 240,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4
          ),
          itemCount: albumList.length,
          itemBuilder: ( _, int i ) {
            final album = albumList[i];
            final imageFile = File('${ musicPlayerProvider.appDirectory }/${ album.id }.jpg');
      
            return RippleTile(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ArtworkFileImage(
                    tag: 'album-screen-${ album.id }',
                    artworkId: album.id,
                    artworkType: ArtworkType.ALBUM,
                    width: double.maxFinite,
                    height: 190,
                    imageFile: imageFile,
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      album.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "${ album.numOfSongs } ${ (album.numOfSongs > 1) ? 'songs' : 'song' }",
                      style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlbumSelectedScreen( albumSelected: album ))
                );
              }
            );
          },
        ),
      ),
    );
  }
}