import 'package:on_audio_query/on_audio_query.dart';

import '../../models/artist_content_model.dart';
import '../../models/multiple_search_model.dart';

class MusicPlayerState {
  MusicPlayerState({
    SongModel? songPlayed,
    this.isShuffling = false,
    this.isLoading = false,
    this.isCreatingArtworks = false,
    this.appDirectory = '',
    this.songList = const [],
    this.albumList = const [],
    this.genreList = const [],
    this.artistList = const [],
    this.playLists = const [],
    this.favoriteList = const [],
    this.favoriteSongList = const [],
    this.currentPlaylist = const [],
    this.albumCollection = const {},
    this.artistCollection = const {},
    this.genreCollection = const {},
    this.playlistCollection = const {},
  }) : songPlayed = songPlayed ?? SongModel({'_id': 0});

  final SongModel songPlayed;
  final bool isShuffling;
  final bool isLoading;
  final bool isCreatingArtworks;
  final String appDirectory;
  final List<SongModel> songList;
  final List<AlbumModel> albumList;
  final List<GenreModel> genreList;
  final List<ArtistModel> artistList;
  final List<PlaylistModel> playLists;
  final List<SongModel> favoriteList;
  final List<String> favoriteSongList;
  final List<SongModel> currentPlaylist;
  final Map<int, List<SongModel>> albumCollection;
  final Map<int, ArtistContentModel> artistCollection;
  final Map<int, List<SongModel>> genreCollection;
  final Map<int, List<SongModel>> playlistCollection;

  bool isFavoriteSong(int id) => favoriteSongList.contains(id.toString());

  MultipleSearchModel searchByQuery(String query) {
    final q = query.toLowerCase();
    return MultipleSearchModel(
      songs: songList.where((s) => s.title.toLowerCase().contains(q)).toList(),
      albums: albumList.where((a) => a.album.toLowerCase().contains(q)).toList(),
      artists: artistList.where((a) => a.artist.toLowerCase().contains(q)).toList(),
    );
  }

  MusicPlayerState copyWith({
    SongModel? songPlayed,
    bool? isShuffling,
    bool? isLoading,
    bool? isCreatingArtworks,
    String? appDirectory,
    List<SongModel>? songList,
    List<AlbumModel>? albumList,
    List<GenreModel>? genreList,
    List<ArtistModel>? artistList,
    List<PlaylistModel>? playLists,
    List<SongModel>? favoriteList,
    List<String>? favoriteSongList,
    List<SongModel>? currentPlaylist,
    Map<int, List<SongModel>>? albumCollection,
    Map<int, ArtistContentModel>? artistCollection,
    Map<int, List<SongModel>>? genreCollection,
    Map<int, List<SongModel>>? playlistCollection,
  }) {
    return MusicPlayerState(
      songPlayed: songPlayed ?? this.songPlayed,
      isShuffling: isShuffling ?? this.isShuffling,
      isLoading: isLoading ?? this.isLoading,
      isCreatingArtworks: isCreatingArtworks ?? this.isCreatingArtworks,
      appDirectory: appDirectory ?? this.appDirectory,
      songList: songList ?? this.songList,
      albumList: albumList ?? this.albumList,
      genreList: genreList ?? this.genreList,
      artistList: artistList ?? this.artistList,
      playLists: playLists ?? this.playLists,
      favoriteList: favoriteList ?? this.favoriteList,
      favoriteSongList: favoriteSongList ?? this.favoriteSongList,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      albumCollection: albumCollection ?? this.albumCollection,
      artistCollection: artistCollection ?? this.artistCollection,
      genreCollection: genreCollection ?? this.genreCollection,
      playlistCollection: playlistCollection ?? this.playlistCollection,
    );
  }
}
