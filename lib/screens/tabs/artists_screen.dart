import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_player_app/screens/artist_selected_screen.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:music_player_app/widgets/ripple_tile.dart';

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
      : artistList.isNotEmpty
        ? ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: artistList.length,
          itemBuilder: ( _, int i ) {
            final artist = artistList[i];
            return RippleTile(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric( horizontal: 15 ),
                title: Text(artist.artist),
                subtitle: Text(artist.numberOfAlbums.toString()),
                leading: ArtworkImage(
                  artworkId: artist.id,
                  type: ArtworkType.ARTIST,
                  width: 60,
                  height: 60,
                  size: 300,
                  radius: BorderRadius.circular(4),
                ),
              ),
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (_) => ArtistSelectedScreen( artistSelected: artist) ));
              },
            );
          } 
        )
        : const Center( 
          child: Text('No Artists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        );
  }
}