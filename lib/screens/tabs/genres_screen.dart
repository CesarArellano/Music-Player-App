import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import 'package:music_player_app/screens/genre_selected_screen.dart';
import 'package:music_player_app/widgets/widgets.dart';

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
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : genreList.isNotEmpty
        ? ListView.builder(
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