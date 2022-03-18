import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:music_player_app/widgets/widgets.dart';
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

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator( color: Colors.white,) )
      : songList.isNotEmpty
        ? RawScrollbar(
          interactive: false,
          thickness: 10,
          thumbColor: Colors.amber,
          minThumbLength: 40.0,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: songList.length,
            itemBuilder: ( _, int i ) {
              final song = songList[i];
              return RippleTile(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist ?? 'No Artist'),                
                  leading: ArtworkImage(
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
              ),
        )
      : const Center( 
        child: Text('No Songs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
      );
  }
}