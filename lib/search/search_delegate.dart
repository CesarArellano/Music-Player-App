import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel, QueryArtworkWidget, ArtworkType;

import 'package:music_player_app/widgets/widgets.dart';
import 'package:music_player_app/providers/music_player_provider.dart';

import '../helpers/music_actions.dart';

class MusicSearchDelegate extends SearchDelegate {

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: ThemeData().colorScheme.copyWith(
        primary: Colors.white
      ),
      hintColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF003A7C),
      )
      
    );
  }

  @override
  String get searchFieldLabel => 'Buscar canción';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () => query = '', 
        icon: const Icon(Icons.clear),
        splashRadius: 22,
      )
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null), 
      icon: const Icon( Icons.arrow_back ),
      splashRadius: 22,
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _emptyContainer();
  }

  @override
  Widget buildSuggestions(BuildContext context) {

    if( query.isEmpty ) {
      return _emptyContainer();
    }
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Container(
      color: const Color(0xFF003A7C),
      child: FutureBuilder(
        future: musicPlayerProvider.searchSongByQuery(query),
        builder: ( _, AsyncSnapshot<List<SongModel>> asyncSnapshot) {
          if( !asyncSnapshot.hasData) {
            return _emptyContainer();
          }
          final songs = asyncSnapshot.data;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: songs!.length,
            itemBuilder: (_, int i) => _songItem(context, songs[i], musicPlayerProvider)
          );
        }
      ),
    );
  }

  Widget _emptyContainer() {
    return Container(
      color: const Color(0xFF003A7C),
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 130,
          color: Colors.white,
        )
      ),
    );
  }

  Widget _songItem(BuildContext context, SongModel song, MusicPlayerProvider musicPlayerProvider ) {
    return RippleTile(
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: QueryArtworkWidget(
          keepOldArtwork: true,
          id: song.id,
          type: ArtworkType.AUDIO,
        ),
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist ?? 'No Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
        // onTap: () => Navigator.pushNamed(context, 'details', arguments: song),
      ),
      onTap: () =>  MusicActions.songPlayAndPause(context, song),
    );
  } 
}