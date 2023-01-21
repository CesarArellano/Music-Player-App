import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:focus_music_player/widgets/custom_icon_text_button.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
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
  final ScrollController _scrollController = ScrollController();
  String? appBarTitle;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSongs();
    _scrollController.addListener(() {
      if( _scrollController.position.pixels >= 70 && appBarTitle == null ) {
        setState(() => appBarTitle = widget.albumSelected.album);
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<MusicPlayerProvider>(context, listen: false).searchByAlbumId( widget.albumSelected.id );
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final imageGeneralFile = File('${ musicPlayerProvider.appDirectory }/${ widget.albumSelected.id }.jpg');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: appBarTitle == null 
          ? null
          : Text(appBarTitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search, color: AppTheme.lightTextColor),
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
                    ArtworkFileImage(
                      artworkId: widget.albumSelected.id,
                      artworkType: ArtworkType.ALBUM,
                      imageFile: imageGeneralFile,
                      width: 175,
                      height: 175,
                    ),
                    const SizedBox(width: 15),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.albumSelected.album, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                          const SizedBox(height: 10),
                          Text(widget.albumSelected.artist.valueEmpty('No Artist'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor)),
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
                padding: const EdgeInsets.symmetric(horizontal: 15),
                width: double.infinity,
                height: 50,
                child: CustomIconTextButton(
                  label: 'PLAY ALL',
                  icon: Icons.play_arrow,
                  onPressed: () {
                    final song = musicPlayerProvider.albumCollection[widget.albumSelected.id]![0];
                    final heroId = 'album-song-${ song.id }';

                    MusicActions.songPlayAndPause(
                      context,
                      song,
                      TypePlaylist.album,
                      id: widget.albumSelected.id,
                      heroId: heroId
                    );
                  }
                ),
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ( musicPlayerProvider.albumCollection[widget.albumSelected.id] ?? [] ).length,
                itemBuilder: (_, int i) {
                  final song = musicPlayerProvider.albumCollection[widget.albumSelected.id]![i];
                  final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
                  final heroId = 'album-song-${ song.id }';
                  return RippleTile(
                    child: ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 5),
                          Text('${ i + 1 }'),
                          SizedBox(width: ( i + 1 >= 10) ? 18 : 25 ),
                          ArtworkFileImage(
                            artworkId: widget.albumSelected.id,
                            artworkType: ArtworkType.ALBUM,
                            imageFile: imageFile,
                            tag: heroId,
                          ),
                        ],
                      ),
                      title: Text(song.title.value(), maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.artist.valueEmpty('No Artist'), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12)),
                    ),
                    onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.album, id: widget.albumSelected.id, heroId: heroId),
                    onLongPress: () {
                      showModalBottomSheet(
                        context: context,
                        builder:( _ ) => MoreSongOptionsModal(song: song)
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || musicPlayerProvider.songPlayed.title.value().isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}