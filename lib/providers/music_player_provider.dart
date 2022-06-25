import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class MusicPlayerProvider extends ChangeNotifier {

  final OnAudioQuery onAudioQuery = OnAudioQuery();

  AudioModel _songPlayed = AudioModel({ 'title': '', '_id': 0});
  bool _isLoading = false;
  bool _isShuffling = false;

  Map<int, List<AudioModel>> albumCollection = {};
  Map<int, List<AudioModel>> artistCollection = {};
  Map<int, List<AudioModel>> genreCollection = {};

  List<AudioModel> songList = [];
  List<AlbumModel> albumList = [];
  List<GenreModel> genreList = [];
  List<ArtistModel> artistList = [];
  List<PlaylistModel> playLists = [];

  List<AudioModel> currentPlaylist = [];
  
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

  AudioModel get songPlayed => _songPlayed;

  set songPlayed( AudioModel value ) {
    _songPlayed = value;
    notifyListeners();
  }

  void getAllSongs() async {
    _isLoading = true;
    if( ! await onAudioQuery.permissionsStatus() ) {
      await onAudioQuery.permissionsRequest();
    }
    
    songList = await onAudioQuery.querySongs();
    songList = songList.map((e) {
      final usefulPath = e.data;
      final pathSegments = usefulPath.split('/');
      String finalPath = '';
      
      for(int i = 0; i < pathSegments.length; i++) {
        if( i + 1 == pathSegments.length ) break;
        finalPath += '/${ pathSegments[i] }';
      }

      return e.copyWith(uri: '$finalPath/cover.jpg');
    }).toList();

    // albumList = await onAudioQuery.queryAlbums();
    genreList = await onAudioQuery.queryGenres();
    artistList = await onAudioQuery.queryArtists();
    playLists = await onAudioQuery.queryPlaylists();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshPlaylist() async {
    _isLoading = true;
    playLists = await onAudioQuery.queryPlaylists();
    _isLoading = false;
    notifyListeners();
  }

  Future<List<AudioModel>> searchSongByQuery(String query) async {
    List<AudioModel> songList = await onAudioQuery.querySongs(
      filter: MediaFilter.forGenres(
        toQuery: {
          MediaColumns.Audio.TITLE: [query.toString()]
        }
      ),
    );
    return songList;
  }

  Future<void> searchByAlbumId(int albumId) async {
    
    if( albumCollection.containsKey(albumId) ) return;

    _isLoading = true;
    albumCollection[albumId] = await onAudioQuery.querySongs(
      filter: MediaFilter.forAlbums(
        toQuery: {
          MediaColumns.Audio.ALBUM_ID: [albumId.toString()]
        },
        albumSortType: AlbumSortType.NUM_OF_SONGS, 
      ),
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchByArtistId(int artistId) async {
    
    if( artistCollection.containsKey(artistId) ) return;

    _isLoading = true;
    artistCollection[artistId] = await onAudioQuery.querySongs(
      filter: MediaFilter.forArtists(
        toQuery: {
          MediaColumns.Audio.ARTIST_ID: [artistId.toString()],
        },
        artistSortType: ArtistSortType.NUM_OF_ALBUMS
      ),
    );
    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchByGenreId(int genreId) async {
    
    if( genreCollection.containsKey(genreId) ) return;

    _isLoading = true;
    genreCollection[genreId] = await onAudioQuery.querySongs(
      filter: MediaFilter.forGenres(
        toQuery: {
          MediaColumns.Audio.GENRE_ID: [genreId.toString()]
        }
      ),
    );
    _isLoading = false;
    notifyListeners();
  }

}