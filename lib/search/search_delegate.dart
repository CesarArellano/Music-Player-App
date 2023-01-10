import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType, SongModel;
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../widgets/artwork_image.dart';
import '../widgets/more_song_options_modal.dart';
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
    final imageFile = File(MusicActions.getArtworkPath(song.data) ?? '');
    
    return RippleTile(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
        leading: imageFile.existsSync() 
          ? ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.file(
              imageFile,
              width: 55,
              height: 55,
            ),
          )
          : ArtworkImage(
            artworkId: song.id,
            type: ArtworkType.AUDIO,
            width: 55,
            height: 55,
            size: 250,
            radius: BorderRadius.circular(3),
          ),
        title: Text(song.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(song.artist ?? 'No Artist', maxLines: 1, overflow: TextOverflow.ellipsis),
        // onTap: () => Navigator.pushNamed(context, 'details', arguments: song),
      ),
      onTap: () =>  MusicActions.songPlayAndPause(context, song, TypePlaylist.songs),
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(5), topLeft: Radius.circular(5))),
          backgroundColor: AppTheme.primaryColor,
          builder:(context) => MoreSongOptionsModal(song: song)
        );
      },
    );
  } 
}