import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_player_app/helpers/music_actions.dart';
import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/widgets/widgets.dart';

import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';

class GenreSelectedScreen extends StatefulWidget {
  const GenreSelectedScreen({
    Key? key,
    required this.genreSelected
  }) : super(key: key);

  final GenreModel genreSelected;

  @override
  State<GenreSelectedScreen> createState() => _GenreSelectedScreenState();
}

class _GenreSelectedScreenState extends State<GenreSelectedScreen> {

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  void getSongs() async {
    await Provider.of<MusicPlayerProvider>(context, listen: false).searchByGenreId( widget.genreSelected.id );
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        centerTitle: true,
        title: const Text('Genre Details'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF003A7C),
                Color(0xCC174A85)
              ]
            ),
          )
        ),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
      ),
      body: musicPlayerProvider.isLoading
        ? const Center( child: CircularProgressIndicator(color: Colors.black) )
        : Stack(
          children: [
            const CustomBackground(),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: 
                      [
                        ArtworkImage(
                          artworkId: widget.genreSelected.id,
                          type: ArtworkType.GENRE,
                          width: 150,
                          height: 150,
                          size: 600,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.genreSelected.genre,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${ widget.genreSelected.numOfSongs } ${ ( widget.genreSelected.numOfSongs > 1) ? 'Songs' : 'Song' }",
                                style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w400)
                              ),
                            ],
                          ),
                        )
                      ]
                    ),
                  ),
                  const Divider(color: Colors.white54, height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: musicPlayerProvider.genreCollection[widget.genreSelected.id]!.length,
                    itemBuilder: (_, int i) {
                      final song = musicPlayerProvider.genreCollection[widget.genreSelected.id]![i];
                      return RippleTile(
                        child: ListTile(
                          leading: ArtworkImage(
                            artworkId: song.albumId ?? 1,
                            type: ArtworkType.ALBUM,
                            width: 50,
                            height: 50,
                            size: 250,
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist ?? 'No Artist')
                        ),
                        onTap: () {
                          MusicActions.songPlayAndPause(context, song, TypePlaylist.genre, id: widget.genreSelected.id );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            )
          ],
        )
    );
  }
}