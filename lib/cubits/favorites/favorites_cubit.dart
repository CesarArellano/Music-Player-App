import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../../data/repositories/preferences_repository.dart';
import 'favorites_state.dart';

export 'favorites_state.dart';

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({required PreferencesRepository preferences})
      : _prefs = preferences,
        super(const FavoritesState());

  final PreferencesRepository _prefs;

  /// Called once after the song library loads to decode persisted IDs.
  Future<void> initFavorites(List<SongModel> allSongs) async {
    final ids = _prefs.favoriteSongList;
    final favorites = await Isolate.run(() {
      final byId = {for (final s in allSongs) s.id: s};
      return ids
          .map((id) => byId[int.tryParse(id)])
          .whereType<SongModel>()
          .toList();
    });
    emit(FavoritesState(
      favoriteList: favorites,
      favoriteSongList: ids,
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
