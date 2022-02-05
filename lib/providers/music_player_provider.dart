import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicPlayerProvider extends ChangeNotifier {

  final OnAudioQuery onAudioQuery = OnAudioQuery();

  String _songPlayed = '';
  bool _isLoading = false;
  List<SongModel> songList = [];
  List<AlbumModel> albumList = [];

  MusicPlayerProvider() {
    getAllSongs();
  }

  bool get isLoading => _isLoading;

  set isLoading( bool value ) {
    _isLoading = value;
    notifyListeners();
  }

  String get songPlayed => _songPlayed;

  set songPlayed( String value ) {
    _songPlayed = value;
    notifyListeners();
  }

  void getAllSongs() async {
    _isLoading = true;
    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    songList = await onAudioQuery.querySongs();
    albumList = await onAudioQuery.queryAlbums();
    _isLoading = false;
    notifyListeners();
  }

}