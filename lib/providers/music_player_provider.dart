import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import '../audio_player_handler.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../models/artist_content_model.dart';
import '../models/multiple_search_model.dart';
import '../share_prefs/user_preferences.dart';


class MusicPlayerProvider extends ChangeNotifier {

  final OnAudioQuery onAudioQuery = audioPlayerHandler.get<OnAudioQuery>();

  SongModel _songPlayed = SongModel({ '_id': 0 });
  
  String appDirectory = '';
  bool isLoading = false;
  bool isCreatingArtworks = false;
  bool _isShuffling = false;

  Map<int, List<SongModel>> albumCollection = {};
  Map<int, ArtistContentModel> artistCollection = {};
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
    final userPrefs = UserPreferences();
    bool createArtworks = forceCreatingArtworks;
    
    appDirectory = UserPreferences().appDirectory;

    if( !userPrefs.isNotFirstTime ) {
      appDirectory = (await getApplicationDocumentsDirectory()).path;
      UserPreferences().appDirectory = appDirectory;
      createArtworks = true;
    }
    
    isCreatingArtworks = createArtworks;
    isLoading = true;
    
    notifyListeners();

    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    
    songList = await onAudioQuery.querySongs();
    albumList = await onAudioQuery.queryAlbums();
    genreList = await onAudioQuery.queryGenres();
    artistList = await onAudioQuery.queryArtists();

    if( Platform.isAndroid ) {
      playLists = await onAudioQuery.queryPlaylists();
    }

    decodeFavoriteSongs();
    await createAllArtworks(createArtworks);
    
    userPrefs.numberOfSongs = songList.length;
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

  MultipleSearchModel searchByQuery(String query) {
    final newQuery = query.toLowerCase();
    
    final songs = songList.where((song) => song.title.value().toLowerCase().contains(newQuery)).toList();
    final albums = albumList.where((album) => album.album.value().toLowerCase().contains(newQuery)).toList();
    final artists = artistList.where((artist) => artist.artist.value().toLowerCase().contains(newQuery)).toList();

    return MultipleSearchModel(
      songs: songs,
      albums: albums,
      artists: artists,
    );
  }

  void searchByAlbumId(int albumId, { bool force = false }) {
    
    if( albumCollection.containsKey(albumId) && !force ) return;

    List<SongModel> tempAlbumList = [ ...songList.where((song) => song.albumId == albumId ) ];
    tempAlbumList.sort((a, b) => a.id.compareTo(b.id));
    albumCollection[albumId] = tempAlbumList;
  }

  void searchByArtistId(int artistId, { bool force = false }) {
    
    if( artistCollection.containsKey(artistId) && !force ) return;
      
    List<SongModel> tempArtistList =  [ ...songList.where((element) => element.artistId == artistId) ];
    List<int> tempAlbumIds = [];
    List<AlbumModel> tempAlbums = [];
    int totalDurationInMilliseconds = 0;
    
    for (SongModel song in tempArtistList) {
      totalDurationInMilliseconds += song.duration ?? 0;
      if( song.albumId.value() == 0 ) continue;
      tempAlbumIds = [...tempAlbumIds, song.albumId! ];
    }

    tempAlbumIds = tempAlbumIds.toSet().toList();
    
    for (int albumId in tempAlbumIds) {
      tempAlbums.add( albumList.firstWhere((album) => album.id == albumId ));
    }

    tempArtistList.sort((a, b) => a.id.compareTo(b.id));
    artistCollection[artistId] = ArtistContentModel(
      songs: tempArtistList,
      albums: tempAlbums,
      totalDuration: Duration(milliseconds: totalDurationInMilliseconds).getTimeString()
    );
  }

  Future<void> searchByGenreId(int genreId, { bool force = false }) async {
    
    if( genreCollection.containsKey(genreId) && !force ) return;

    List<SongModel> tempGenreList = await onAudioQuery.queryAudiosFrom( AudiosFromType.GENRE_ID, genreId );
    tempGenreList.sort((a, b) => a.id.compareTo(b.id));
    genreCollection[genreId] = tempGenreList;
  }

  Future<void> searchByPlaylistId(int playlistId, { bool force = false }) async {
    
    if( playlistCollection.containsKey(playlistId) && !force ) return;

    isLoading = true;
    notifyListeners();
    playlistCollection[playlistId] = await onAudioQuery.queryAudiosFrom( AudiosFromType.PLAYLIST, playlistId );
    isLoading = false;
    notifyListeners();
  }

  void decodeFavoriteSongs() {
    List<SongModel> tempFavoriteSongs = [];

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

  Future<void> createAllArtworks(bool createArtworks) async {
    if( createArtworks || ( UserPreferences().numberOfSongs != songList.length ) ) {
      final songListLength = songList.length;
      for (int i = 0; i < songListLength; i++) {
        File imageTempFile = File('$appDirectory/${ songList[i].albumId }.jpg');
        if( imageTempFile.existsSync() ) continue;
        await MusicActions.createArtwork(imageTempFile, songList[i].id);
      }
      isCreatingArtworks = false;
      UserPreferences().isNotFirstTime = true;
    }
  }
}