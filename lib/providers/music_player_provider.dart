import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/helpers/music_actions.dart';
import 'package:music_player_app/helpers/null_extension.dart';
import 'package:music_player_app/share_prefs/user_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';


class MusicPlayerProvider extends ChangeNotifier {

  final OnAudioQuery onAudioQuery = OnAudioQuery();

  SongModel _songPlayed = SongModel({});
  String appDirectory = '';
  bool isLoading = false;
  bool isCreatingArtworks = false;
  bool _isShuffling = false;

  Map<int, List<SongModel>> albumCollection = {};
  Map<int, List<SongModel>> artistCollection = {};
  Map<int, List<SongModel>> genreCollection = {};
  Map<int, List<SongModel>> playlistCollection = {};

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
    decodeFavoriteSongs();
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

  Future<void> getAllSongs({ bool forceCreatingArtworks = false }) async {
    final createArtworks = ( !UserPreferences().isFirstTime || forceCreatingArtworks );

    isLoading = true;
    if( createArtworks ) {
      isCreatingArtworks = true;
    }
    notifyListeners();

    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    
    songList = await onAudioQuery.querySongs();
    albumList = await onAudioQuery.queryAlbums();
    genreList = await onAudioQuery.queryGenres();
    artistList = await onAudioQuery.queryArtists();
    playLists = await onAudioQuery.queryPlaylists();
    appDirectory = (await getApplicationDocumentsDirectory()).path;

    if( createArtworks ) {
      final songListLength = songList.length;
      for (int i = 0; i < songListLength; i++) {
        File imageTempFile = File('$appDirectory/${ songList[i].albumId }.jpg');
        if( imageTempFile.existsSync() ) continue;
        await MusicActions.createArtwork(imageTempFile, songList[i].id);
      }
      isCreatingArtworks = false;
      UserPreferences().isFirstTime = true;
    }
    
    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPlaylist() async {
    isLoading = true;
    notifyListeners();
    playLists = await onAudioQuery.queryPlaylists();
    isLoading = false;
    notifyListeners();
  }

  Future<List<SongModel>> searchSongByQuery(String query) async {
    return songList.where((song) => song.title.value().toLowerCase().contains(query)).toList();
  }

  Future<void> searchByAlbumId(int albumId, { bool force = false }) async {
    
    if( albumCollection.containsKey(albumId) && !force ) return;

    isLoading = true;
    notifyListeners();
    albumCollection[albumId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.ALBUM_ID, albumId );
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchByArtistId(int artistId, { bool force = false }) async {
    
    if( artistCollection.containsKey(artistId) && !force ) return;

    isLoading = true;
    notifyListeners();
    artistCollection[artistId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.ARTIST_ID, artistId );
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchByGenreId(int genreId, { bool force = false }) async {
    
    if( genreCollection.containsKey(genreId) && !force ) return;

    isLoading = true;
    notifyListeners();
    genreCollection[genreId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.GENRE_ID, genreId );
    isLoading = false;
    notifyListeners();
  }

  Future<void> searchByPlaylistId(int playlistId, { bool force = false }) async {
    
    if( playlistCollection.containsKey(playlistId) && !force ) return;

    isLoading = true;
    notifyListeners();
    playlistCollection[playlistId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.PLAYLIST, playlistId );
    isLoading = false;
    notifyListeners();
  }

  Future<void> decodeFavoriteSongs() async {
    List<SongModel> tempFavoriteSongs = [];
    
    songList = await onAudioQuery.querySongs();
    favoriteSongList = UserPreferences().favoriteSongList;

    final int favoriteListLength = favoriteSongList.length;

    for (int i = 0; i < favoriteListLength; i ++) {
      final index = songList.indexWhere((song) => song.id == int.tryParse(favoriteSongList[i]));
      if( index != -1 ) {
        tempFavoriteSongs.add( songList[index] );
      }
    }

    favoriteList = [ ...tempFavoriteSongs ];
  }
}