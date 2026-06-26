import 'package:on_audio_query/on_audio_query.dart';

class FavoritesState {
  const FavoritesState({
    this.favoriteList = const [],
    this.favoriteSongList = const [],
  });

  final List<SongModel> favoriteList;
  final List<String> favoriteSongList;

  bool isFavoriteSong(int id) => favoriteSongList.contains(id.toString());

  FavoritesState copyWith({
    List<SongModel>? favoriteList,
    List<String>? favoriteSongList,
  }) {
    return FavoritesState(
      favoriteList: favoriteList ?? this.favoriteList,
      favoriteSongList: favoriteSongList ?? this.favoriteSongList,
    );
  }
}
