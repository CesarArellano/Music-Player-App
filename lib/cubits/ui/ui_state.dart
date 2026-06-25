import 'package:flutter/material.dart';

class UIState {
  const UIState({
    this.currentDominantColor,
    this.currentHeroId = '',
    this.dominantColorCollection = const {},
  });

  final Color? currentDominantColor;
  final String currentHeroId;
  final Map<String, String> dominantColorCollection;

  Color get dominantColor => currentDominantColor ?? Colors.black;

  Color get songPlayedThemeColor =>
      (dominantColor.computeLuminance() < 0.4) ? Colors.white : Colors.black;

  Brightness get songPlayedBrightness =>
      (dominantColor.computeLuminance() < 0.4) ? Brightness.light : Brightness.dark;

  TextTheme get songPlayedTypography => (dominantColor.computeLuminance() < 0.4)
      ? Typography.whiteCupertino
      : Typography.blackCupertino;

  UIState copyWith({
    Color? currentDominantColor,
    bool clearDominantColor = false,
    String? currentHeroId,
    Map<String, String>? dominantColorCollection,
  }) {
    return UIState(
      currentDominantColor: clearDominantColor
          ? null
          : (currentDominantColor ?? this.currentDominantColor),
      currentHeroId: currentHeroId ?? this.currentHeroId,
      dominantColorCollection:
          dominantColorCollection ?? this.dominantColorCollection,
    );
  }
}
