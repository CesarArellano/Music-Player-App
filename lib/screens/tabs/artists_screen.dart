import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../providers/music_player_provider.dart';

class ArtistScreen extends StatefulWidget {
  
  const ArtistScreen({Key? key}) : super(key: key);

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final artistList = musicPlayerProvider.artistList;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator() )
      : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: artistList.length,
        itemBuilder: ( _, int i ) {
          final artist = artistList[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric( vertical: 10, horizontal: 15),
            title: Text(artist.artist),
            subtitle: Text(artist.numberOfAlbums.toString()),
            onTap: () {

            },
            leading: QueryArtworkWidget(
              id: artist.id,
              type: ArtworkType.ARTIST,
            ),
          );
        } 
    );
  }
}