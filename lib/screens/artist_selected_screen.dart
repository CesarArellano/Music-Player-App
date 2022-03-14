import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_player_app/helpers/music_actions.dart';
import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/widgets/widgets.dart';

import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';

class ArtistSelectedScreen extends StatefulWidget {
  const ArtistSelectedScreen({
    Key? key,
    required this.artistSelected
  }) : super(key: key);

  final ArtistModel artistSelected;

  @override
  State<ArtistSelectedScreen> createState() => _ArtistSelectedScreenState();
}

class _ArtistSelectedScreenState extends State<ArtistSelectedScreen> {

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  void getSongs() async {
    await Provider.of<MusicPlayerProvider>(context, listen: false).searchByArtistId( widget.artistSelected.id );
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        centerTitle: true,
        title: const Text('Artist Details'),
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
                          artworkId: widget.artistSelected.id,
                          type: ArtworkType.ARTIST,
                          width: 150,
                          height: 150,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.artistSelected.artist,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "${ widget.artistSelected.numberOfAlbums } ${ (widget.artistSelected.numberOfAlbums ?? 1 ) > 1 ? 'Albums' : 'Album'} • ${ widget.artistSelected.numberOfTracks } ${ ((widget.artistSelected.numberOfTracks ?? 1 ) > 1) ? 'Songs' : 'Song' }",
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
                    itemCount: musicPlayerProvider.artistCollection[widget.artistSelected.id]!.length,
                    itemBuilder: (_, int i) {
                      final song = musicPlayerProvider.artistCollection[widget.artistSelected.id]![i];
                      return RippleTile(
                        child: ListTile(
                          leading: ArtworkImage(
                            artworkId: song.albumId ?? 1,
                            type: ArtworkType.ALBUM,
                            width: 50,
                            height: 50,
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist ?? 'No Artist')
                        ),
                        onTap: () {
                          MusicActions.songPlayAndPause(context, song, TypePlaylist.artist, id: widget.artistSelected.id );
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