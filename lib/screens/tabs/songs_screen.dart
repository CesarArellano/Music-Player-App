import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../helpers/music_actions.dart';
import '../../providers/music_player_provider.dart';
import '../../widgets/artwork_image.dart';
import '../../widgets/widgets.dart';

class SongsScreen extends StatefulWidget {
  
  const SongsScreen({Key? key}) : super(key: key);

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> with AutomaticKeepAliveClientMixin {

  final ScrollController _scrollController = ScrollController();
  @override
  bool get wantKeepAlive => true;


  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songList = musicPlayerProvider.songList;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator( color: Colors.white,) )
      : songList.isNotEmpty
        ? ListView.builder(
          controller: _scrollController,
          itemCount: songList.length,
          itemBuilder: ( _, int i ) {
            final song = songList[i];
                                  final imageFile = File(MusicActions.getArtworkPath(song.data) ?? '');

            return RippleTile(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                title: Text(song.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(song.artist ?? 'No Artist'),                
                leading: imageFile.existsSync() 
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: Image.file(
                    imageFile,
                    width: 50,
                    height: 50,
                  ),
                )
                : ArtworkImage(
                  artworkId: song.id,
                  type: ArtworkType.AUDIO,
                  width: 50,
                  height: 50,
                  size: 250,
                  radius: BorderRadius.circular(2.5),
                ),
              ),
              onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.songs),
            );
          } 
            )
      : const Center( 
        child: Text('No Songs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
      );
  }
}