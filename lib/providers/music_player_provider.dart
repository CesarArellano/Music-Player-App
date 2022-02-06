import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicPlayerProvider extends ChangeNotifier {

  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  final OnAudioQuery onAudioQuery = OnAudioQuery();

  Duration _current = const Duration(milliseconds: 0);
  SongModel _songPlayed = SongModel({ 'title': '' });
  bool _isLoading = false;

  List<SongModel> songList = [];
  List<AlbumModel> albumList = [];
  List<GenreModel> genreList = [];
  List<ArtistModel> artistList = [];
  List<PlaylistModel> playLists = [];

  MusicPlayerProvider() {
    getAllSongs();
  }

  bool get isLoading => _isLoading;

  set isLoading( bool value ) {
    _isLoading = value;
    notifyListeners();
  }

  SongModel get songPlayed => _songPlayed;

  set songPlayed( SongModel value ) {
    _songPlayed = value;
    notifyListeners();
  }

  Duration get current => _current;
  
  set current(Duration value) {
    _current= value;
    notifyListeners();
  }

  void getAllSongs() async {
    _isLoading = true;
    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    
    songList = await onAudioQuery.querySongs();
    albumList = await onAudioQuery.queryAlbums();
    genreList = await onAudioQuery.queryGenres();
    artistList = await onAudioQuery.queryArtists();
    playLists = await onAudioQuery.queryPlaylists();

    _isLoading = false;
    notifyListeners();
  }

  Future<List<SongModel>> searchSongByQuery(String query) async {
    List<dynamic> songList = await onAudioQuery.queryWithFilters(query, WithFiltersType.AUDIOS );
    return songList.toSongModel();
  }

}