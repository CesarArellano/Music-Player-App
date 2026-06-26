import 'package:flutter/foundation.dart' show listEquals;
import 'package:on_audio_query/on_audio_query.dart';

class ArtistContentModel {
  ArtistContentModel({
    this.albums = const [],
    this.songs = const [],
    this.totalDuration = '',
  });

  final List<AlbumModel> albums;
  final List<SongModel> songs;
  final String totalDuration;

  ArtistContentModel copyWith({
    List<AlbumModel>? albums,
    List<SongModel>? songs,
    String? totalDuration,
  }) => ArtistContentModel(
    albums: albums ?? this.albums,
    songs: songs ?? this.songs,
    totalDuration: totalDuration ?? this.totalDuration,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistContentModel &&
          listEquals(albums, other.albums) &&
          listEquals(songs, other.songs) &&
          totalDuration == other.totalDuration;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(albums), Object.hashAll(songs), totalDuration);
}
