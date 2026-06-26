import 'dart:typed_data' show Uint8List;

import 'package:music_query_selector/music_query_selector.dart';

abstract interface class AudioRepository {
  Future<bool> requestPermissions();
  Future<List<SongModel>> querySongs();
  Future<List<AlbumModel>> queryAlbums();
  Future<List<GenreModel>> queryGenres();
  Future<List<ArtistModel>> queryArtists();
  Future<List<PlaylistModel>> queryPlaylists();
  Future<List<SongModel>> queryAudiosByGenreId(int genreId);
  Future<List<SongModel>> queryAudiosByPlaylistId(int playlistId);
  Future<Uint8List?> queryArtwork(int songId, {int size = 500});
  Future<bool> createPlaylist(String name);
  Future<bool> addToPlaylist(int playlistId, int songId);
  Future<bool> removeFromPlaylist(int playlistId, int songId);
  Future<bool> removePlaylist(int playlistId);
}
