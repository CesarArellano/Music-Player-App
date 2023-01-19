import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../widgets/custom_icon_text_button.dart';
import '../widgets/widgets.dart';

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
  final ScrollController _scrollController = ScrollController();
  String? appBarTitle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSongs();
    _scrollController.addListener(() {
      if( _scrollController.position.pixels >= 70 && appBarTitle == null ) {
        setState(() => appBarTitle = widget.genreSelected.genre);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(() { });
    _scrollController.dispose();
  }

  void getSongs() {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await musicPlayerProvider.searchByGenreId( widget.genreSelected.id, force: (musicPlayerProvider.genreCollection[widget.genreSelected.id]?.length ?? 0) != widget.genreSelected.numOfSongs);
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: appBarTitle == null 
          ? null
          : Text(appBarTitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
      ),
      body: isLoading
        ? const Center( child: CircularProgressIndicator() )
        : SingleChildScrollView(
          controller: _scrollController,
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
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                width: double.infinity,
                height: 50,
                child: CustomIconTextButton(
                  label: 'PLAY ALL',
                  icon: Icons.play_arrow,
                  onPressed: () {
                    final song = musicPlayerProvider.genreCollection[widget.genreSelected.id]![0];
                    final heroId = 'genre-song-${ song.id }';

                    MusicActions.songPlayAndPause(
                      context,
                      song,
                      TypePlaylist.genre,
                      id: widget.genreSelected.id,
                      heroId: heroId
                    );
                  }
                ),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ( musicPlayerProvider.genreCollection[widget.genreSelected.id] ?? [] ).length,
                itemBuilder: (_, int i) {
                  final song = musicPlayerProvider.genreCollection[widget.genreSelected.id]![i];
                  final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
                  final heroId = 'genre-song-${ song.id }';

                  return RippleTile(
                    child: CustomListTile(
                      imageFile: imageFile,
                      title: song.title ?? '',
                      subtitle: song.artist ?? 'No Artist',
                      artworkId: song.id,
                      tag: heroId,
                    ),
                    onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.genre, id: widget.genreSelected.id, heroId: heroId),
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder:( _ ) => MoreSongOptionsModal(song: song, disabledDeleteButton: true)
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title ?? '').isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}