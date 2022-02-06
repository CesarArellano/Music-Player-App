import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

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
      : ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: songList.length,
        itemBuilder: ( _, int i ) {
          final song = songList[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric( vertical: 10, horizontal: 15),
            title: Text(song.title),
            subtitle: Text(song.artist ?? 'No Artist'),
            onTap: () {

              final path = song.data;

              if( musicPlayerProvider.songPlayed.title != song.title ) {
                musicPlayerProvider.audioPlayer.open(
                  Audio.file(path),
                  headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
                  showNotification: true,
                );
                musicPlayerProvider.songPlayed = song;
              } else {
                if( musicPlayerProvider.audioPlayer.isPlaying.value ) {
                  musicPlayerProvider.audioPlayer.pause();
                } else {
                  musicPlayerProvider.audioPlayer.play();
                }
              }

            },
            leading: QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
            ),
          );
        } 
    );
  }
}