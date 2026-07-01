import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/services/artwork_cache_service.dart';
import '../../extensions/extensions.dart';
import '../../models/artist_content_model.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    required AudioRepository audioRepository,
    required ArtworkCacheService artworkCacheService,
    required PreferencesRepository preferences,
    this.onSongsLoaded,
  })  : _audio = audioRepository,
        _artwork = artworkCacheService,
        _prefs = preferences,
        super(LibraryState()) {
    getAllSongs();
  }

  final AudioRepository _audio;
  final ArtworkCacheService _artwork;
  final PreferencesRepository _prefs;

  /// Called once after the initial song list loads, so FavoritesCubit can
  /// decode persisted favourite IDs into SongModel instances.
  final Future<void> Function(List<SongModel>)? onSongsLoaded;

  Future<void> getAllSongs({bool forceCreatingArtworks = false}) async {
    bool createArtworks = forceCreatingArtworks;
    final appDirectory = await _artwork.resolveAppDirectory();

    if (!_prefs.isNotFirstTime) {
      createArtworks = true;
    }

    emit(state.copyWith(
      appDirectory: appDirectory,
      isCreatingArtworks: createArtworks,
      isLoading: true,
      isLoadingCatalogue: true,
    ));

    final hasPermission = await _audio.requestPermissions();
    if (!hasPermission) {
      emit(state.copyWith(
        isLoading: false,
        isLoadingCatalogue: false,
        isCreatingArtworks: false,
      ));
      return;
    }

    // All four queries fire concurrently. Songs are awaited first so the
    // Songs tab becomes interactive as soon as possible; the other futures
    // are already in-flight and will resolve shortly after.
    final songsFuture = _audio.querySongs();
    final albumsFuture = _audio.queryAlbums();
    final genresFuture = _audio.queryGenres();
    final artistsFuture = _audio.queryArtists();
    final playlistsFuture =
        Platform.isAndroid ? _audio.queryPlaylists() : null;

    final songList = await songsFuture;
    emit(state.copyWith(songList: songList, isLoading: false));
    await onSongsLoaded?.call(songList);

    // Pick up catalogue results — all already in-flight from above.
    final (albumList, genreList, artistList) = await (
      albumsFuture,
      genresFuture,
      artistsFuture,
    ).wait;

    final playLists = (await playlistsFuture) ?? state.playLists;

    emit(state.copyWith(
      albumList: albumList,
      genreList: genreList,
      artistList: artistList,
      playLists: playLists,
      isLoadingCatalogue: false,
    ));

    await _artwork.buildArtworkCache(
      songs: songList,
      appDirectory: appDirectory,
      force: createArtworks,
    );

    _prefs.numberOfSongs = songList.length;
    emit(state.copyWith(isCreatingArtworks: false));
  }

  Future<void> refreshPlaylist() async {
    emit(state.copyWith(isLoading: true));
    final playLists = await _audio.queryPlaylists();
    emit(state.copyWith(playLists: playLists, isLoading: false));
  }

  void searchByAlbumId(int albumId, {bool force = false}) {
    if (state.albumCollection.containsKey(albumId) && !force) return;

    final songs = [...state.songList.where((s) => s.albumId == albumId)]
      ..sort((a, b) => a.id.compareTo(b.id));

    final updated = Map<int, List<SongModel>>.from(state.albumCollection)
      ..[albumId] = songs;
    emit(state.copyWith(albumCollection: updated));
  }

  Future<void> searchByArtistId(int artistId, {bool force = false}) async {
    if (state.artistCollection.containsKey(artistId) && !force) return;

    final allSongs = state.songList;
    final allAlbums = state.albumList;

    final result = await Isolate.run(() {
      final artistSongs = allSongs.where((s) => s.artistId == artistId).toList();
      int totalMs = 0;
      final albumIds = <int>{};
      for (final song in artistSongs) {
        totalMs += song.duration ?? 0;
        if ((song.albumId ?? 0) != 0) albumIds.add(song.albumId!);
      }
      final albumById = {for (final a in allAlbums) a.id: a};
      final albums = albumIds
          .map((id) => albumById[id])
          .whereType<AlbumModel>()
          .toList();
      artistSongs.sort((a, b) => a.id.compareTo(b.id));
      return (songs: artistSongs, albums: albums, totalMs: totalMs);
    });

    final updated = Map<int, ArtistContentModel>.from(state.artistCollection)
      ..[artistId] = ArtistContentModel(
        songs: result.songs,
        albums: result.albums,
        totalDuration: Duration(milliseconds: result.totalMs).timeString,
      );
    emit(state.copyWith(artistCollection: updated));
  }

  Future<void> searchByGenreId(int genreId, {bool force = false}) async {
    if (state.genreCollection.containsKey(genreId) && !force) return;

    final songs = await _audio.queryAudiosByGenreId(genreId)
      ..sort((a, b) => a.id.compareTo(b.id));

    final updated = Map<int, List<SongModel>>.from(state.genreCollection)
      ..[genreId] = songs;
    emit(state.copyWith(genreCollection: updated));
  }

  Future<void> searchByPlaylistId(int playlistId, {bool force = false}) async {
    if (state.playlistCollection.containsKey(playlistId) && !force) return;

    emit(state.copyWith(isLoading: true));
    final songs = await _audio.queryAudiosByPlaylistId(playlistId);

    final updated = Map<int, List<SongModel>>.from(state.playlistCollection)
      ..[playlistId] = songs;
    emit(state.copyWith(playlistCollection: updated, isLoading: false));
  }
}
