import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../helpers/helpers.dart';
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
    required String appDirectory,
  }) async {
    final fileImage = FileImage(File('$appDirectory/$albumId.jpg'));

    if (albumId == null || !fileImage.file.existsSync()) {
      emit(state.copyWith(clearDominantColor: true));
      return;
    }

    if (state.dominantColorCollection.containsKey(albumId)) {
      final hex = state.dominantColorCollection[albumId];
      emit(state.copyWith(
        currentDominantColor: hex != null ? Helpers.fromHex(hex) : null,
        clearDominantColor: hex == null,
      ));
      return;
    }

    final color = (await PaletteGenerator.fromImageProvider(fileImage))
            .dominantColor
            ?.color ??
        Colors.white;
    final hex = color.toARGB32().toRadixString(16);

    final updated = Map<String, String>.from(state.dominantColorCollection)
      ..[albumId] = hex;

    UserPreferences().dominantColorCollection = updated;

    emit(state.copyWith(
      dominantColorCollection: updated,
      currentDominantColor: Helpers.fromHex(hex),
    ));
  }
}
