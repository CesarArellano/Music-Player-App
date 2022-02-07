import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicPlayerProvider extends ChangeNotifier {

  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  final OnAudioQuery onAudioQuery = OnAudioQuery();

  SongModel _songPlayed = SongModel({ 'title': '' });
  bool _isLoading = false;
  bool _isShuffling = false;

  Map<int, List<SongModel>> albumCollection = {};

  List<SongModel> songList = [];
  List<AlbumModel> albumList = [];
  List<GenreModel> genreList = [];
  List<ArtistModel> artistList = [];
  List<PlaylistModel> playLists = [];

  List<SongModel> currentPlaylist = [];

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }
  
  MusicPlayerProvider() {
    getAllSongs();
  }

  bool get isLoading => _isLoading;

  set isLoading( bool value ) {
    _isLoading = value;
    notifyListeners();
  }

  bool get isShuffling => _isShuffling;

  set isShuffling( bool value ) {
    _isShuffling = value;
    notifyListeners();
  }

  SongModel get songPlayed => _songPlayed;

  set songPlayed( SongModel value ) {
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

  Future<void> searchByAlbumId(int albumId) async {
    
    if( albumCollection.containsKey(albumId) ) return;

    _isLoading = true;
    albumCollection[albumId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.ALBUM_ID, albumId );
    _isLoading = false;
    notifyListeners();
  }

}