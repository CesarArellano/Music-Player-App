import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/widgets.dart';
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

    return songList.isNotEmpty
      ? ListView.builder(
        itemCount: songList.length,
        itemBuilder: ( _, int i ) {
          final song = songList[i];
          final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
          final heroId = 'favorite-song-${ song.id }';

          return RippleTile(
            onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.songs, heroId: heroId ),
            onLongPress: () {
              showModalBottomSheet(
                context: context,
                builder:(context) => MoreSongOptionsModal(song: song)
              );
            },
            child: CustomListTile(
              title: song.title ?? '',
              subtitle: song.artist ?? 'No Artist',                
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