import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../providers/music_player_provider.dart';

class SongsScreen extends StatelessWidget {
  
  SongsScreen({Key? key}) : super(key: key);

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songList = musicPlayerProvider.songList;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator() )
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

              final uri = song.data;

              if( musicPlayerProvider.songPlayed != song.title ) {
                _audioPlayer.play('file://$uri', isLocal: true);
                musicPlayerProvider.songPlayed = song.title;
              } else {
                if( _audioPlayer.state == PlayerState.PLAYING ) {
                  _audioPlayer.pause();
                } else {
                  _audioPlayer.play('file://$uri', isLocal: true);
                }
              }

            },
            leading: QueryArtworkWidget(
              id: songList[i].id,
              type: ArtworkType.AUDIO,
            ),
          );
        } 
    );
  }

}