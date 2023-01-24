import 'package:on_audio_query/on_audio_query.dart';

class ArtistContentModel {

  ArtistContentModel({
    this.albums = const [],
    this.songs = const [],
    this.totalDuration = ''
  });

  final List<AlbumModel> albums;
  final List<SongModel> songs;
  final String totalDuration;

}