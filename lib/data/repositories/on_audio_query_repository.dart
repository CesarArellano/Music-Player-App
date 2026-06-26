import 'dart:typed_data' show Uint8List;

import 'package:on_audio_query/on_audio_query.dart';

import 'audio_repository.dart';

class OnAudioQueryRepository implements AudioRepository {
  OnAudioQueryRepository(this._query);

  final OnAudioQuery _query;

  @override
  Future<bool> requestPermissions() async {
    if (await _query.permissionsStatus()) return true;
    return _query.permissionsRequest();
  }

  @override
  Future<List<SongModel>> querySongs() => _query.querySongs();

  @override
  Future<List<AlbumModel>> queryAlbums() => _query.queryAlbums();

  @override
  Future<List<GenreModel>> queryGenres() => _query.queryGenres();

  @override
  Future<List<ArtistModel>> queryArtists() => _query.queryArtists();

  @override
  Future<List<PlaylistModel>> queryPlaylists() => _query.queryPlaylists();

  @override
  Future<List<SongModel>> queryAudiosByGenreId(int genreId) =>
      _query.queryAudiosFrom(AudiosFromType.GENRE_ID, genreId);

  @override
  Future<List<SongModel>> queryAudiosByPlaylistId(int playlistId) =>
      _query.queryAudiosFrom(AudiosFromType.PLAYLIST, playlistId);

  @override
  Future<Uint8List?> queryArtwork(int songId, {int size = 500}) =>
      _query.queryArtwork(songId, ArtworkType.AUDIO, size: size);

  @override
  Future<bool> createPlaylist(String name) => _query.createPlaylist(name);

  @override
  Future<bool> addToPlaylist(int playlistId, int songId) =>
      _query.addToPlaylist(playlistId, songId);

  @override
  Future<bool> removeFromPlaylist(int playlistId, int songId) =>
      _query.removeFromPlaylist(playlistId, songId);

  @override
  Future<bool> removePlaylist(int playlistId) =>
      _query.removePlaylist(playlistId);
}
