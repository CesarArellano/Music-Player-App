import 'package:on_audio_query/on_audio_query.dart' show SongModel;

import '../cubits/library/library_state.dart';
import '../helpers/music_actions.dart' show PlaylistType;
import '../models/artist_content_model.dart';
import '../extensions/extensions.dart';

abstract interface class PlaylistResolver {
  List<SongModel> resolve(
    LibraryState libraryState, {
    int? id,
    List<SongModel> favoriteList,
  });
}

class _SongsResolver implements PlaylistResolver {
  const _SongsResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      libraryState.songList;
}

class _AlbumResolver implements PlaylistResolver {
  const _AlbumResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      libraryState.albumCollection[id].value();
}

class _ArtistResolver implements PlaylistResolver {
  const _ArtistResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      (libraryState.artistCollection[id] ?? ArtistContentModel()).songs;
}

class _GenreResolver implements PlaylistResolver {
  const _GenreResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      libraryState.genreCollection[id].value();
}

class _PlaylistResolver implements PlaylistResolver {
  const _PlaylistResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      libraryState.playlistCollection[id].value();
}

class _FavoritesResolver implements PlaylistResolver {
  const _FavoritesResolver();
  @override
  List<SongModel> resolve(LibraryState libraryState, {int? id, List<SongModel> favoriteList = const []}) =>
      favoriteList;
}

/// Maps each [PlaylistType] to its [PlaylistResolver] strategy.
/// Adding a new type = new class + one map entry. Nothing else changes.
class PlaylistResolverFactory {
  const PlaylistResolverFactory._();

  static const Map<PlaylistType, PlaylistResolver> _resolvers = {
    PlaylistType.songs: _SongsResolver(),
    PlaylistType.album: _AlbumResolver(),
    PlaylistType.artist: _ArtistResolver(),
    PlaylistType.genre: _GenreResolver(),
    PlaylistType.playlist: _PlaylistResolver(),
    PlaylistType.favorites: _FavoritesResolver(),
  };

  static List<SongModel> resolve(
    PlaylistType type,
    LibraryState libraryState, {
    int? id,
    List<SongModel> favoriteList = const [],
  }) =>
      (_resolvers[type] ?? const _SongsResolver()).resolve(
        libraryState,
        id: id,
        favoriteList: favoriteList,
      );
}
