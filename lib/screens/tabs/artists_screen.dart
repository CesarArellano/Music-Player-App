import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../cubits/cubits.dart';
import '../../extensions/extensions.dart';
import '../../widgets/widgets.dart';
import '../artist_selected_screen.dart';

class ArtistScreen extends StatefulWidget {
  const ArtistScreen({super.key});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final libraryState = context.watch<LibraryCubit>().state;
    final artistList = libraryState.artistList;

    return libraryState.isLoading
        ? CustomLoader(isCreatingArtworks: libraryState.isCreatingArtworks)
        : artistList.isNotEmpty
            ? OrientationBuilder(
                builder: (_, orientation) => GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 2 : 1,
                    childAspectRatio: 4,
                  ),
                  itemCount: artistList.length,
                  itemBuilder: (_, int i) {
                    final artist = artistList[i];

                    return RippleTile(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15.0, vertical: 8),
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
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${artist.numberOfAlbums} ${artist.numberOfAlbums.value() > 1 ? 'Albums' : 'Album'} • ${artist.numberOfTracks} Songs',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ArtistSelectedScreen(artistSelected: artist),
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text(
                  'No Artists',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
  }
}
