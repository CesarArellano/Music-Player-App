import 'dart:io' show Platform, File;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import '../../audio_player_handler.dart';
import '../../extensions/extensions.dart';
import '../../models/artist_content_model.dart';
import '../../share_prefs/user_preferences.dart';
import 'music_player_state.dart';

export 'music_player_state.dart';

class MusicPlayerCubit extends Cubit<MusicPlayerState> {
  final OnAudioQuery _onAudioQuery = audioPlayerHandler.get<OnAudioQuery>();

  MusicPlayerCubit() : super(MusicPlayerState()) {
    getAllSongs();
  }

  Future<void> getAllSongs({bool forceCreatingArtworks = false}) async {
    final userPrefs = UserPreferences();
    bool createArtworks = forceCreatingArtworks;

    String appDirectory = userPrefs.appDirectory;

    if (!userPrefs.isNotFirstTime) {
      appDirectory = (await getApplicationDocumentsDirectory()).path;
      userPrefs.appDirectory = appDirectory;
      createArtworks = true;
    }

    emit(state.copyWith(
      appDirectory: appDirectory,
      isCreatingArtworks: createArtworks,
      isLoading: true,
    ));

    if (!await _onAudioQuery.permissionsStatus()) {
      await _onAudioQuery.permissionsRequest();
    }

    final songList = await _onAudioQuery.querySongs();
    final albumList = await _onAudioQuery.queryAlbums();
    final genreList = await _onAudioQuery.queryGenres();
    final artistList = await _onAudioQuery.queryArtists();

    List<PlaylistModel> playLists = state.playLists;
    if (Platform.isAndroid) {
      playLists = await _onAudioQuery.queryPlaylists();
    }

    emit(state.copyWith(
      songList: songList,
      albumList: albumList,
      genreList: genreList,
      artistList: artistList,
      playLists: playLists,
    ));

    _decodeFavoriteSongs(songList);
    await _createAllArtworks(createArtworks, appDirectory, songList);

    userPrefs.numberOfSongs = state.songList.length;
    emit(state.copyWith(isLoading: false));
  }

  Future<void> refreshPlaylist() async {
    emit(state.copyWith(isLoading: true));
    final playLists = await _onAudioQuery.queryPlaylists();
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

    final songs = await _onAudioQuery.queryAudiosFrom(AudiosFromType.GENRE_ID, genreId)
      ..sort((a, b) => a.id.compareTo(b.id));

    final updated = Map<int, List<SongModel>>.from(state.genreCollection)
      ..[genreId] = songs;
    emit(state.copyWith(genreCollection: updated));
  }

  Future<void> searchByPlaylistId(int playlistId, {bool force = false}) async {
    if (state.playlistCollection.containsKey(playlistId) && !force) return;

    emit(state.copyWith(isLoading: true));
    final songs = await _onAudioQuery.queryAudiosFrom(AudiosFromType.PLAYLIST, playlistId);

    final updated = Map<int, List<SongModel>>.from(state.playlistCollection)
      ..[playlistId] = songs;
    emit(state.copyWith(playlistCollection: updated, isLoading: false));
  }

  void updateSongPlayed(SongModel song) => emit(state.copyWith(songPlayed: song));

  void updateIsShuffling(bool value) => emit(state.copyWith(isShuffling: value));

  void updateCurrentPlaylist(List<SongModel> playlist) =>
      emit(state.copyWith(currentPlaylist: playlist));

  void updateFavorites({
    required List<SongModel> favoriteList,
    required List<String> favoriteSongList,
  }) {
    emit(state.copyWith(
      favoriteList: favoriteList,
      favoriteSongList: favoriteSongList,
    ));
  }

  void _decodeFavoriteSongs(List<SongModel> songList) {
    final favoriteSongList = UserPreferences().favoriteSongList;
    final favorites = <SongModel>[];

    for (final id in favoriteSongList) {
      final index = songList.indexWhere((s) => s.id == int.tryParse(id));
      if (index != -1) favorites.add(songList[index]);
    }

    emit(state.copyWith(
      favoriteSongList: favoriteSongList,
      favoriteList: favorites,
    ));
  }

  Future<void> _createAllArtworks(
    bool createArtworks,
    String appDirectory,
    List<SongModel> songList,
  ) async {
    if (!createArtworks && UserPreferences().numberOfSongs == songList.length) return;

    for (final song in songList) {
      final file = File('$appDirectory/${song.albumId}.jpg');
      if (file.existsSync()) continue;
      final bytes = await _onAudioQuery.queryArtwork(song.id, ArtworkType.AUDIO, size: 500);
      if (bytes != null) await file.writeAsBytes(bytes);
    }

    emit(state.copyWith(isCreatingArtworks: false));
    UserPreferences().isNotFirstTime = true;
  }
}
