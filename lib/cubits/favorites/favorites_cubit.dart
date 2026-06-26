import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../audio_player_handler.dart';
import '../../data/repositories/preferences_repository.dart';
import 'favorites_state.dart';

export 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({PreferencesRepository? preferences})
      : _prefs = preferences ?? audioPlayerHandler<PreferencesRepository>(),
        super(const FavoritesState());

  final PreferencesRepository _prefs;

  /// Called once after the song library loads to decode persisted IDs.
  void initFavorites(List<SongModel> allSongs) {
    final favoriteSongList = _prefs.favoriteSongList;
    final favorites = <SongModel>[];

    for (final id in favoriteSongList) {
      final index = allSongs.indexWhere((s) => s.id == int.tryParse(id));
      if (index != -1) favorites.add(allSongs[index]);
    }

    emit(FavoritesState(
      favoriteList: favorites,
      favoriteSongList: favoriteSongList,
    ));
  }

  void updateFavorites({
    required List<SongModel> favoriteList,
    required List<String> favoriteSongList,
  }) {
    emit(state.copyWith(
      favoriteList: favoriteList,
      favoriteSongList: favoriteSongList,
    ));
  }
}
