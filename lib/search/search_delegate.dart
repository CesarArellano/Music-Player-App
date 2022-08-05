import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType, SongModel;
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../widgets/artwork_image.dart';
import '../widgets/widgets.dart';

class MusicSearchDelegate extends SearchDelegate {

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      // useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white
      ),
      hintColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF001F42),
      ),
      scaffoldBackgroundColor: AppTheme.primaryColor
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
    return FutureBuilder(
      future: musicPlayerProvider.searchSongByQuery(query),
      builder: ( _, AsyncSnapshot<List<SongModel>> asyncSnapshot) {
        if( !asyncSnapshot.hasData) {
          return _emptyContainer();
        }
        final songs = asyncSnapshot.data;
        return ListView.builder(
          itemCount: songs!.length,
          itemBuilder: (_, int i) => _songItem(context, songs[i], musicPlayerProvider)
        );
      }
    );
  }

  Widget _emptyContainer() {
    return const Center(
      child: Icon(
        Icons.music_note,
        size: 130,
        color: Colors.white,
      )
    );
  }

  Widget _songItem(BuildContext context, SongModel song, MusicPlayerProvider musicPlayerProvider ) {
    return RippleTile(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: ArtworkImage(
          artworkId: song.id,
          type: ArtworkType.AUDIO,
          width: 60,
          height: 60,
          size: 250,
          radius: BorderRadius.circular(2.5),
        ),
        title: Text(song.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist ?? 'No Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
        // onTap: () => Navigator.pushNamed(context, 'details', arguments: song),
      ),
      onTap: () =>  MusicActions.songPlayAndPause(context, song, TypePlaylist.songs),
    );
  } 
}