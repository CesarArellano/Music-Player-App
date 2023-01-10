import 'package:flutter/material.dart';
import 'package:music_player_app/share_prefs/user_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';


class MusicPlayerProvider extends ChangeNotifier {

  final OnAudioQuery onAudioQuery = OnAudioQuery();

  SongModel _songPlayed = SongModel({});
  bool _isLoading = false;
  bool _isShuffling = false;

  Map<int, List<SongModel>> albumCollection = {};
  Map<int, List<SongModel>> artistCollection = {};
  Map<int, List<SongModel>> genreCollection = {};

  List<SongModel> songList = [];
  List<AlbumModel> albumList = [];
  List<GenreModel> genreList = [];
  List<ArtistModel> artistList = [];
  List<PlaylistModel> playLists = [];
  List<SongModel> _favoriteList = [];

  List<SongModel> currentPlaylist = [];
  List<String> _favoriteSongList = [];
  
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

  List<SongModel> get favoriteList => _favoriteList;

  set favoriteList( List<SongModel> value ) {
    _favoriteList = value;
    notifyListeners();
  }

  List<String> get favoriteSongList => _favoriteSongList;
  
  bool isFavoriteSong(int id) {
    return _favoriteSongList.contains(id.toString());
  }

  set favoriteSongList( List<String> value ) {
    _favoriteSongList = value;
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
    favoriteSongList = UserPreferences().favoriteSongList;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPlaylist() async {
    _isLoading = true;
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

  Future<void> searchByArtistId(int artistId) async {
    
    if( artistCollection.containsKey(artistId) ) return;

    _isLoading = true;
    artistCollection[artistId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.ARTIST_ID, artistId );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchByGenreId(int genreId) async {
    
    if( genreCollection.containsKey(genreId) ) return;

    _isLoading = true;
    genreCollection[genreId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.GENRE_ID, genreId );
    _isLoading = false;
    notifyListeners();
  }

}