import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final OnAudioQuery onAudioQuery = OnAudioQuery();

  String songPlayed = '';
  bool _isLoading = false;
  List<SongModel> songList = [];

  @override
  void initState() {
    super.initState();
    searchSongs();
  }

  void searchSongs() async {
    setState(() => _isLoading = true);
    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    songList = await onAudioQuery.querySongs();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
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

                if( songPlayed != song.title ) {
                  _audioPlayer.play('file://$uri', isLocal: true);
                  songPlayed = song.title;
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
        )
    );
  }
}
