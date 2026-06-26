import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../cubits/cubits.dart';
import '../../widgets/widgets.dart';
import '../genre_selected_screen.dart';

class GenresScreen extends StatefulWidget {
  const GenresScreen({super.key});

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final libraryState = context.watch<LibraryCubit>().state;
    final genreList = libraryState.genreList;

    return libraryState.isLoading
        ? CustomLoader(isCreatingArtworks: libraryState.isCreatingArtworks)
        : genreList.isNotEmpty
            ? OrientationBuilder(
                builder: (_, orientation) => GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 2 : 1,
                    childAspectRatio: 5.5,
                  ),
                  itemCount: genreList.length,
                  itemBuilder: (_, int i) {
                    final genre = genreList[i];

                    return RippleTile(
                      child: CustomListTile(
                        title: genre.genre,
                        subtitle:
                            '${genre.numOfSongs} ${genre.numOfSongs > 1 ? 'Songs' : 'Song'}',
                        artworkId: genre.id,
                        artworkType: ArtworkType.GENRE,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              GenreSelectedScreen(genreSelected: genre),
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text(
                  'No Genres',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
  }
}
