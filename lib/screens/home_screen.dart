import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final OnAudioQuery onAudioQuery = OnAudioQuery();
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
          itemBuilder: ( _, int i ) => ListTile(
            contentPadding: const EdgeInsets.symmetric( vertical: 10, horizontal: 15),
            title: Text(songList[i].title),
            subtitle: Text(songList[i].artist ?? 'No Artist'),
            onTap: () async {
              final uri = '${ songList[i].uri }';
              final file = File(uri);
              print(file.path);

            },
            leading: QueryArtworkWidget(
              id: songList[i].id,
              type: ArtworkType.AUDIO,
            ),
          )
        )
    );
  }
}
