import 'dart:io' show Platform;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../audio_player_handler.dart';
import '../../data/repositories/audio_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../data/services/artwork_cache_service.dart';
import '../../extensions/extensions.dart';
import '../../models/artist_content_model.dart';
import 'library_state.dart';

export 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    AudioRepository? audioRepository,
    ArtworkCacheService? artworkCacheService,
    PreferencesRepository? preferences,
    this.onSongsLoaded,
  })  : _audio = audioRepository ?? audioPlayerHandler<AudioRepository>(),
        _artwork = artworkCacheService ?? audioPlayerHandler<ArtworkCacheService>(),
        _prefs = preferences ?? audioPlayerHandler<PreferencesRepository>(),
        super(LibraryState()) {
    getAllSongs();
  }

  final AudioRepository _audio;
  final ArtworkCacheService _artwork;
  final PreferencesRepository _prefs;

  /// Called once after the initial song list loads, so FavoritesCubit can
  /// decode persisted favourite IDs into SongModel instances.
  final void Function(List<SongModel>)? onSongsLoaded;

  Future<void> getAllSongs({bool forceCreatingArtworks = false}) async {
    bool createArtworks = forceCreatingArtworks;
    String appDirectory = _prefs.appDirectory;

    if (!_prefs.isNotFirstTime) {
      appDirectory = await _artwork.resolveAppDirectory();
      createArtworks = true;
    }

    emit(state.copyWith(
      appDirectory: appDirectory,
      isCreatingArtworks: createArtworks,
      isLoading: true,
    ));

    await _audio.requestPermissions();

    final songList = await _audio.querySongs();
    final albumList = await _audio.queryAlbums();
    final genreList = await _audio.queryGenres();
    final artistList = await _audio.queryArtists();

    List<PlaylistModel> playLists = state.playLists;
    if (Platform.isAndroid) {
      playLists = await _audio.queryPlaylists();
    }

    emit(state.copyWith(
      songList: songList,
      albumList: albumList,
      genreList: genreList,
      artistList: artistList,
      playLists: playLists,
    ));

    onSongsLoaded?.call(songList);

    await _artwork.buildArtworkCache(
      songs: songList,
      appDirectory: appDirectory,
      force: createArtworks,
    );

    _prefs.numberOfSongs = songList.length;
    emit(state.copyWith(isLoading: false, isCreatingArtworks: false));
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

  void searchByArtistId(int artistId, {bool force = false}) {
    if (state.artistCollection.containsKey(artistId) && !force) return;

    final artistSongs = [...state.songList.where((s) => s.artistId == artistId)];
    int totalMs = 0;
    final albumIds = <int>{};

    for (final song in artistSongs) {
      totalMs += song.duration ?? 0;
      if (song.albumId.value() != 0) albumIds.add(song.albumId!);
    }

    final albums = albumIds
        .map((id) => state.albumList.firstWhere((a) => a.id == id))
        .toList();

    artistSongs.sort((a, b) => a.id.compareTo(b.id));

    final updated = Map<int, ArtistContentModel>.from(state.artistCollection)
      ..[artistId] = ArtistContentModel(
        songs: artistSongs,
        albums: albums,
        totalDuration: Duration(milliseconds: totalMs).getTimeString(),
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
