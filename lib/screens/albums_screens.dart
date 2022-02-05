import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';

import '../providers/music_player_provider.dart';

class AlbumsScreen extends StatelessWidget {
  
  AlbumsScreen({Key? key}) : super(key: key);
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final albumList = musicPlayerProvider.albumList;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator() )
      : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 240,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4
          ),
          physics: const BouncingScrollPhysics(),
          itemCount: albumList.length,
          itemBuilder: ( _, int i ) {
            final album = albumList[i];
            return InkWell(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QueryArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
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
            );
          },
    ),
      );
  }
}