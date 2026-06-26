import 'package:on_audio_query/on_audio_query.dart' show SongModel;

import '../cubits/favorites/favorites_cubit.dart';
import '../data/repositories/preferences_repository.dart';

class FavoritesService {
  FavoritesService({
    required FavoritesCubit favoritesCubit,
    required PreferencesRepository preferences,
  })  : _cubit = favoritesCubit,
        _prefs = preferences;

  final FavoritesCubit _cubit;
  final PreferencesRepository _prefs;

  void toggle(
    SongModel song, {
    required FavoritesState favoritesState,
    required List<SongModel> allSongs,
  }) {
    final favoriteList = [...favoritesState.favoriteList];
    final favoriteSongList = [...favoritesState.favoriteSongList];
    final isFavorite = favoritesState.isFavoriteSong(song.id);

    if (isFavorite) {
      favoriteList.removeWhere((s) => s.id == song.id);
      favoriteSongList.removeWhere((id) => id == song.id.toString());
    } else {
      final index = allSongs.indexWhere((s) => s.id == song.id);
      if (index != -1) favoriteList.add(allSongs[index]);
      favoriteSongList.add(song.id.toString());
    }

    _cubit.updateFavorites(
      favoriteList: favoriteList,
      favoriteSongList: favoriteSongList,
    );
    _prefs.favoriteSongList = favoriteSongList;
  }
}
