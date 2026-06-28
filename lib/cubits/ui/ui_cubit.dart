import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../../share_prefs/user_preferences.dart';
import 'ui_state.dart';

export 'ui_state.dart';

class UICubit extends Cubit<UIState> {
  UICubit() : super(const UIState());

  void updateCurrentHeroId(String heroId) =>
      emit(state.copyWith(currentHeroId: heroId));

  void updateDominantColorCollection(Map<String, String> collection) =>
      emit(state.copyWith(dominantColorCollection: collection));

  Future<void> searchDominantColorByAlbumId({
    required String? albumId,
  }) async {
    if (albumId == null) {
      emit(state.copyWith(clearDominantColor: true));
      return;
    }

    // Fast path: color already resolved (in-memory or rehydrated from prefs).
    if (state.dominantColorCollection.containsKey(albumId)) {
      final hex = state.dominantColorCollection[albumId];
      emit(state.copyWith(
        currentDominantColor:
            hex != null ? Color(int.parse(hex, radix: 16)) : null,
        clearDominantColor: hex == null,
      ));
      return;
    }

    final id = int.tryParse(albumId);
    if (id == null) {
      emit(state.copyWith(clearDominantColor: true));
      return;
    }

    // Computed natively from the already-decoded artwork (androidx.palette /
    // Core Image), avoiding a second decode + palette pass on the Dart side.
    final colorValue = await MusicQuerySelector().queryArtworkColor(
      id,
      ArtworkType.ALBUM,
    );

    if (colorValue == null) {
      emit(state.copyWith(clearDominantColor: true));
      return;
    }

    final color = Color(colorValue);
    final hex = colorValue.toRadixString(16);

    final updated = Map<String, String>.from(state.dominantColorCollection)
      ..[albumId] = hex;

    UserPreferences().dominantColorCollection = updated;

    emit(state.copyWith(
      dominantColorCollection: updated,
      currentDominantColor: color,
    ));
  }
}
