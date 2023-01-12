import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/widgets.dart';
import 'package:provider/provider.dart';

import '../../helpers/music_actions.dart';
import '../../providers/music_player_provider.dart';

class SongsScreen extends StatefulWidget {
  
  const SongsScreen({Key? key}) : super(key: key);

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songList = musicPlayerProvider.songList;

    return ( musicPlayerProvider.isLoading )
      ? const Center( child: CircularProgressIndicator() )
      : songList.isNotEmpty
        ? ListView.builder(
          itemCount: songList.length,
          itemBuilder: ( _, int i ) {
            final song = songList[i];
            final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');

            return RippleTile(
              child: CustomListTile(
                title: song.title ?? '',
                subtitle: song.artist ?? 'No Artist',
                artworkId: song.id,
                imageFile: imageFile
              ),
              onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.songs),
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder:( _ ) => MoreSongOptionsModal(song: song)
                );
              },
            );
          } 
        )
      : const Center( 
        child: Text(
          'No Songs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        )
      );
  }
}