import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../widgets/artwork_image.dart';
import '../widgets/widgets.dart';

class AlbumSelectedScreen extends StatefulWidget {
  const AlbumSelectedScreen({
    Key? key,
    required this.albumSelected
  }) : super(key: key);

  final AlbumModel albumSelected;

  @override
  State<AlbumSelectedScreen> createState() => _AlbumSelectedScreenState();
}

class _AlbumSelectedScreenState extends State<AlbumSelectedScreen> {

  @override
  void initState() {
    super.initState();
    getSongs();
  }

  void getSongs() async {
    await Provider.of<MusicPlayerProvider>(context, listen: false).searchByAlbumId( widget.albumSelected.id );
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Album Details'),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
      ),
      body: musicPlayerProvider.isLoading
        ? const Center( child: CircularProgressIndicator() )
        : Stack(
          children: [
            const CustomBackground(),
            SingleChildScrollView(
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
                          artworkId: widget.albumSelected.id,
                          type: ArtworkType.ALBUM,
                          width: 150,
                          height: 150,
                          size: 600,
                          radius: BorderRadius.circular(2.5),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.albumSelected.album, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                              const SizedBox(height: 10),
                              Text(widget.albumSelected.artist ?? 'No Artist', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                              const SizedBox(height: 5),
                              Text("${ widget.albumSelected.numOfSongs } ${ (widget.albumSelected.numOfSongs > 1) ? 'songs' : 'song' }"),
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
                    itemCount: musicPlayerProvider.albumCollection[widget.albumSelected.id]!.length,
                    itemBuilder: (_, int i) {
                      final song = musicPlayerProvider.albumCollection[widget.albumSelected.id]![i];
                      return RippleTile(
                        child: ListTile(
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 5),
                              Text('${ i + 1 }'),
                              SizedBox(width: ( i + 1 >= 10) ? 18 : 25 ),
                              ArtworkImage(
                                artworkId: widget.albumSelected.id,
                                type: ArtworkType.ALBUM,
                                width: 50,
                                height: 50,
                                size: 250,
                                radius: BorderRadius.circular(2.5),
                              ),
                            ],
                          ),
                          title: Text(song.title ?? ''),
                          subtitle: Text(song.artist ?? 'No Artist')
                        ),
                        onTap: () {
                          MusicActions.songPlayAndPause(context, song, TypePlaylist.album, id: widget.albumSelected.id );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            )
          ],
      ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title ?? '').isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}