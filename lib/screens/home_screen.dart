import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OnAudioQuery onAudioQuery = OnAudioQuery();
  List<SongModel> songsFound = [];

  @override
  void initState() {
    super.initState();
    searchSongs();
  }

  void searchSongs() async {
    songsFound = await onAudioQuery.querySongs();
    print(songsFound);
    for (SongModel song in songsFound) {
      debugPrint(song.title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('HomeScreen'),
      ),
    );
  }
}