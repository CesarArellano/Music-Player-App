import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:focus_music_player/screens/genre_selected_screen.dart';
import 'package:focus_music_player/widgets/widgets.dart';

import '../../providers/music_player_provider.dart';

class GenresScreen extends StatefulWidget {
  
  const GenresScreen({Key? key}) : super(key: key);

  @override
  State<GenresScreen> createState() => _GenresScreenState();
}

class _GenresScreenState extends State<GenresScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final genreList = musicPlayerProvider.genreList;

    return musicPlayerProvider.isLoading
      ? const CustomLoader()
      : genreList.isNotEmpty
        ? OrientationBuilder(
          builder: ( _, orientation ) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ( orientation == Orientation.landscape ) ?  2 : 1,
              childAspectRatio: 5.5
            ),
            itemCount: genreList.length,
            itemBuilder: ( _, int i ) {
              final genre = genreList[i];
              return RippleTile(
                child: CustomListTile(
                  title: genre.genre,
                  subtitle: '${ genre.numOfSongs } ${ ( genre.numOfSongs > 1) ? 'Songs' : 'Song' }',
                  artworkId: genre.id,
                  artworkType: ArtworkType.GENRE,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => GenreSelectedScreen( genreSelected: genre ))
                  );
                },
              );
            } 
          )
        )
        : const Center( 
          child: Text(
            'No Genres',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold
            )
          )
        );
  }
}