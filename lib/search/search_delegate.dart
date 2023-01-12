import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel;
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../widgets/widgets.dart';

class MusicSearchDelegate extends SearchDelegate {

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        primary: Colors.white
      ),
      hintColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.primaryColor,
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
        return ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: RichText(
                  text: TextSpan(
                  style: const TextStyle(fontSize: 18),
                  children: [
                    const TextSpan(text: 'Songs', style: TextStyle(fontWeight: FontWeight.w500)),
                    TextSpan(text: ' (${ songs?.length })', style: const TextStyle(color: AppTheme.lightTextColor))
                  ]
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Divider(color: AppTheme.lightTextColor),
            ),
            ...songs!.map((song) => _songItem(context, song, musicPlayerProvider))
          ]
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
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
    final heroId = 'search-song-${ song.id }';

    return RippleTile(
      child: CustomListTile(
        imageFile: imageFile,
        title: song.title ?? '',
        subtitle: song.artist ?? 'No Artist',
        artworkId: song.id,
        tag: heroId,
      ),
      onTap: () =>  MusicActions.songPlayAndPause(context, song, TypePlaylist.songs, heroId: heroId),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          builder:(context) => MoreSongOptionsModal(song: song)
        );
      },
    );
  } 
}