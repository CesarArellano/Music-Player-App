import 'package:flutter/foundation.dart' show listEquals;
import 'package:music_query_selector/music_query_selector.dart' show SongModel, AlbumModel, ArtistModel;

class MultipleSearchModel {
  MultipleSearchModel({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });

  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;

  MultipleSearchModel copyWith({
    List<SongModel>? songs,
    List<AlbumModel>? albums,
    List<ArtistModel>? artists,
  }) => MultipleSearchModel(
    songs: songs ?? this.songs,
    albums: albums ?? this.albums,
    artists: artists ?? this.artists,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultipleSearchModel &&
          listEquals(songs, other.songs) &&
          listEquals(albums, other.albums) &&
          listEquals(artists, other.artists);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(songs),
    Object.hashAll(albums),
    Object.hashAll(artists),
  );
}
