import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/widgets.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
      ? const Center ( child: CircularProgressIndicator() )
      : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: genreList.length,
        itemBuilder: ( _, int i ) {
          final genre = genreList[i];
          return RippleTile(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric( vertical: 10, horizontal: 15),
              title: Text(genre.genre),
              subtitle: Text(genre.numOfSongs.toString()),
              leading: QueryArtworkWidget(
                keepOldArtwork: true,
                id: genre.id,
                type: ArtworkType.GENRE,
              ),
            ),
            onTap: () {},
          );
        } 
    );
  }
}