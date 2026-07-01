import 'dart:isolate';

import 'package:music_query_selector/music_query_selector.dart';

import '../../models/artist_content_model.dart';
import '../../models/multiple_search_model.dart';

class LibraryState {
  LibraryState({
    this.isLoading = false,
    this.isLoadingCatalogue = false,
    this.isCreatingArtworks = false,
    this.appDirectory = '',
    this.songList = const [],
    this.albumList = const [],
    this.genreList = const [],
    this.artistList = const [],
    this.playLists = const [],
    this.albumCollection = const {},
    this.artistCollection = const {},
    this.genreCollection = const {},
    this.playlistCollection = const {},
  });

  final bool isLoading;
  final bool isLoadingCatalogue;
  final bool isCreatingArtworks;
  final String appDirectory;
  final List<SongModel> songList;
  final List<AlbumModel> albumList;
  final List<GenreModel> genreList;
  final List<ArtistModel> artistList;
  final List<PlaylistModel> playLists;
  final Map<int, List<SongModel>> albumCollection;
  final Map<int, ArtistContentModel> artistCollection;
  final Map<int, List<SongModel>> genreCollection;
  final Map<int, List<SongModel>> playlistCollection;

  MultipleSearchModel searchByQuery(String query) {
    final q = query.toLowerCase();
    return MultipleSearchModel(
      songs: songList.where((s) => s.title.toLowerCase().contains(q)).toList(),
      albums: albumList.where((a) => a.album.toLowerCase().contains(q)).toList(),
      artists: artistList.where((a) => a.artist.toLowerCase().contains(q)).toList(),
    );
  }

  static Future<MultipleSearchModel> searchAsync({
    required String query,
    required List<SongModel> songList,
    required List<AlbumModel> albumList,
    required List<ArtistModel> artistList,
  }) {
    final q = query.toLowerCase();
    return Isolate.run(() => MultipleSearchModel(
      songs: songList.where((s) => s.title.toLowerCase().contains(q)).toList(),
      albums: albumList.where((a) => a.album.toLowerCase().contains(q)).toList(),
      artists: artistList.where((a) => a.artist.toLowerCase().contains(q)).toList(),
    ));
  }

  LibraryState copyWith({
    bool? isLoading,
    bool? isLoadingCatalogue,
    bool? isCreatingArtworks,
    String? appDirectory,
    List<SongModel>? songList,
    List<AlbumModel>? albumList,
    List<GenreModel>? genreList,
    List<ArtistModel>? artistList,
    List<PlaylistModel>? playLists,
    Map<int, List<SongModel>>? albumCollection,
    Map<int, ArtistContentModel>? artistCollection,
    Map<int, List<SongModel>>? genreCollection,
    Map<int, List<SongModel>>? playlistCollection,
  }) {
    return LibraryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingCatalogue: isLoadingCatalogue ?? this.isLoadingCatalogue,
      isCreatingArtworks: isCreatingArtworks ?? this.isCreatingArtworks,
      appDirectory: appDirectory ?? this.appDirectory,
      songList: songList ?? this.songList,
      albumList: albumList ?? this.albumList,
      genreList: genreList ?? this.genreList,
      artistList: artistList ?? this.artistList,
      playLists: playLists ?? this.playLists,
      albumCollection: albumCollection ?? this.albumCollection,
      artistCollection: artistCollection ?? this.artistCollection,
      genreCollection: genreCollection ?? this.genreCollection,
      playlistCollection: playlistCollection ?? this.playlistCollection,
    );
  }
}
