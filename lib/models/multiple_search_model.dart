import 'package:on_audio_query/on_audio_query.dart' show SongModel, AlbumModel, ArtistModel;

class MultipleSearchModel {
  MultipleSearchModel({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });

  final List<SongModel> songs;
  final List<AlbumModel> albums;
  final List<ArtistModel> artists;
}