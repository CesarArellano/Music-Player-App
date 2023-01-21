import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:focus_music_player/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../../helpers/music_actions.dart';
import '../../providers/music_player_provider.dart';

class FavoriteScreen extends StatefulWidget {
  
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songList = musicPlayerProvider.favoriteList;

    return musicPlayerProvider.isLoading
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : songList.isNotEmpty
        ? ListView.builder(
          itemCount: songList.length,
          itemBuilder: ( _, int i ) {
            final song = songList[i];
            final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
            final heroId = 'favorite-song-${ song.id }';

            return RippleTile(
              onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.favorites, heroId: heroId ),
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder:(context) => MoreSongOptionsModal(song: song, disabledDeleteButton: true)
                );
              },
              child: CustomListTile(
                title: song.title.value(),
                subtitle: song.artist.valueEmpty('No Artist'),                
                imageFile: imageFile,
                artworkId: song.id,
                tag: heroId,
              ),
            );
          } 
        )
        : const Center( 
          child: Text('No Favorites', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
        );
    }
}