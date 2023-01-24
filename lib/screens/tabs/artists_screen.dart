import 'package:flutter/material.dart';
import '../../helpers/null_extension.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';


import '../../providers/music_player_provider.dart';
import '../../widgets/widgets.dart';
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
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : artistList.isNotEmpty
        ? OrientationBuilder(
          builder: ( _, orientation ) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ( orientation == Orientation.landscape ) ? 2 : 1,
              childAspectRatio: 4,
            ),
            itemCount: artistList.length,
            itemBuilder: ( _, int i ) {
              final artist = artistList[i];
              return RippleTile(
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
                        size: 400,
                        radius: BorderRadius.circular(2.5),
                      ),
                      const SizedBox(width: 15),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              artist.artist,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ArtistSelectedScreen( artistSelected: artist ))
                  );
                },
              );
            } 
          ),
        )
        : const Center( 
          child: Text('No Artists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        );
  }
}