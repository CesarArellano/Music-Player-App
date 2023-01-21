import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:music_player_app/theme/app_theme.dart';
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
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final albumList = musicPlayerProvider.albumList;

    return musicPlayerProvider.isLoading
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : albumList.isNotEmpty
        ? Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 235,
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
        )
      : const Center( 
        child: Text(
          'No Albums',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold
          )
        )
      );
  }
}