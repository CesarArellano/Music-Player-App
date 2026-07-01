import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/artwork_repository.dart';
import '../../data/repositories/preferences_repository.dart';
import '../playback_state/playback_state_cubit.dart';
import 'ui_state.dart';

export 'ui_state.dart';

class UICubit extends Cubit<UIState> {
  UICubit({
    required ArtworkRepository artworkRepository,
    required PreferencesRepository preferences,
    required PlaybackStateCubit playbackStateCubit,
  })  : _artwork = artworkRepository,
        _prefs = preferences,
        super(const UIState()) {
    _songSub = playbackStateCubit.stream.listen((playbackState) {
      searchDominantColorByAlbumId(
        albumId: playbackState.songPlayed.albumId?.toString(),
      );
    });
  }

  final ArtworkRepository _artwork;
  final PreferencesRepository _prefs;
  StreamSubscription<PlaybackState>? _songSub;

  @override
  Future<void> close() {
    _songSub?.cancel();
    return super.close();
  }

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
    final colorValue = await _artwork.queryArtworkColor(id);

    if (colorValue == null) {
      emit(state.copyWith(clearDominantColor: true));
      return;
    }

    final color = Color(colorValue);
    final hex = colorValue.toRadixString(16);

    final updated = Map<String, String>.from(state.dominantColorCollection)
      ..[albumId] = hex;

    _prefs.dominantColorCollection = updated;

    emit(state.copyWith(
      dominantColorCollection: updated,
      currentDominantColor: color,
    ));
  }
}
