import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/helpers/null_extension.dart';
import 'package:music_player_app/widgets/ripple_tile.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';


import '../../providers/music_player_provider.dart';
import '../../widgets/artwork_image.dart';
import '../artist_selected_screen.dart';

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
          itemCount: artistList.length,
          itemBuilder: ( _, int i ) {
            final artist = artistList[i];
            return SizedBox(
              width: double.infinity,
              child: RippleTile(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ArtworkImage(
                        artworkId: artist.id,
                        type: ArtworkType.ARTIST,
                        width: 85,
                        height: 85,
                        size: 250,
                        radius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              artist.artist,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${ artist.numberOfAlbums } ${ artist.numberOfAlbums.value() > 1 ? 'Albums' : 'Album' } • ${ artist.numberOfTracks } Songs',
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.push(context, CupertinoPageRoute(builder: (_) => ArtistSelectedScreen( artistSelected: artist) ));
                },
              ),
            );
          } 
        )
        : const Center( 
          child: Text('No Artists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        );
  }
}