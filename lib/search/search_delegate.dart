import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel, ArtworkType;
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../helpers/null_extension.dart';
import '../providers/music_player_provider.dart';
import '../screens/album_selected_screen.dart';
import '../screens/artist_selected_screen.dart';
import '../theme/app_theme.dart';
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
    final searchResult = musicPlayerProvider.searchByQuery(query);
    final songs = searchResult.songs;
    final albums = searchResult.albums;
    final artists = searchResult.artists;

    if( searchResult.songs.isEmpty && searchResult.albums.isEmpty && searchResult.artists.isEmpty ) {
      return _emptyContainer();
    }

    return CustomScrollView(
      slivers: [
        if( songs.isNotEmpty ) 
          _SectionTitle(title: 'Songs', length: songs.length),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final song = songs[index];
            return _songItem(context, song, musicPlayerProvider);
          },
          childCount: songs.length
        )),
        if( artists.isNotEmpty ) 
          _SectionTitle(title: 'Artists', length: artists.length),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final artist = artists[index];
            return RippleTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ArtistSelectedScreen( artistSelected: artist ))
                );
              },
              child: CustomListTile(
                artworkId: artist.id,
                artworkType: ArtworkType.ARTIST,
                title: artist.artist,
                subtitle: '${ artist.numberOfAlbums } ${ artist.numberOfAlbums.value() > 1 ? 'Albums' : 'Album' } • ${ artist.numberOfTracks } Songs'
              )
            );
          },
          childCount: artists.length
        )),
        if( albums.isNotEmpty ) 
          _SectionTitle(title: 'Albums', length: albums.length),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final album = albums[index];
            return RippleTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AlbumSelectedScreen( albumSelected: album ))
                );
              },
              child: CustomListTile(
                artworkId: album.id,
                imageFile: File('${ musicPlayerProvider.appDirectory }/${ album.id }.jpg'),
                title: album.album,
                subtitle: "${ album.numOfSongs } ${ (album.numOfSongs > 1) ? 'songs' : 'song' }",
              )
            );
          },
          childCount: albums.length
        )),
      ],
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
        title: song.title.value(),
        subtitle: song.artist.valueEmpty('No Artist'),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.length,
  });

  final String title;
  final int length;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            RichText(
                text: TextSpan(
                style: const TextStyle(fontSize: 18),
                children: [
                  TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: ' ($length)', style: const TextStyle(color: AppTheme.lightTextColor))
                ]
              ),
            ),
            const Divider(color: AppTheme.lightTextColor)
          ],
        ),
      ),
    );
  }
}