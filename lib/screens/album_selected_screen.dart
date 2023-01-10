import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ), 
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search, color: AppTheme.lightTextColor),
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
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: 
                      [
                        ArtworkImage(
                          artworkId: widget.albumSelected.id,
                          type: ArtworkType.ALBUM,
                          width: 175,
                          height: 175,
                          size: 500,
                          radius: BorderRadius.circular(4),
                        ),
                        const SizedBox(width: 15),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.albumSelected.album, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                              const SizedBox(height: 10),
                              Text(widget.albumSelected.artist ?? 'No Artist', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor)),
                              const SizedBox(height: 5),
                              Text(
                                "${ widget.albumSelected.getMap['minyear'] } • ${ widget.albumSelected.numOfSongs } ${ (widget.albumSelected.numOfSongs > 1) ? 'songs' : 'song' }",
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor)
                              ),
                            ],
                          ),
                        )
                      ]
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    width: double.maxFinite,
                    height: 50,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(2.5) ),
                        backgroundColor: AppTheme.lightTextColor.withOpacity(0.15)
                      ),
                      icon: const Icon(Icons.play_arrow, color: AppTheme.lightTextColor),
                      label: const Text('PLAY ALL'),
                      onPressed: () {
                        MusicActions.songPlayAndPause(
                          context,
                          musicPlayerProvider.albumCollection[widget.albumSelected.id]![0],
                          TypePlaylist.album,
                          id: widget.albumSelected.id
                        );
                      }
                    ),
                  ),
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