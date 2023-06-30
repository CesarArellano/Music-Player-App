import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/helpers/helpers.dart';
import 'package:focus_music_player/share_prefs/user_preferences.dart';
import 'package:palette_generator/palette_generator.dart';

class UIProvider extends ChangeNotifier {

  bool _isSnackbarActive = false;
  bool get isSnackbarActive => _isSnackbarActive;

  set isSnackbarActive( bool newValue ) {
    _isSnackbarActive = newValue;
    notifyListeners();
  }

  AnimationController? _animationController;

  AnimationController? get animationController => _animationController;

  set animationController( AnimationController? newValue ) {
    _animationController = newValue;
    notifyListeners();
  }

  Color? _currentDominantColor;
  Color get currentDominantColor => _currentDominantColor ?? Colors.black;
  Color get songPlayedThemeColor => ( currentDominantColor.computeLuminance() < 0.4 ) ? Colors.white : Colors.black;
  Brightness get songPlayedBrightness => ( currentDominantColor.computeLuminance() < 0.4 ) ? Brightness.light : Brightness.dark;
  TextTheme get songPlayedTypography => ( currentDominantColor.computeLuminance() < 0.4 ) ? Typography.whiteCupertino : Typography.blackCupertino;

  set currentDominantColor(Color? newValue) {
    _currentDominantColor = newValue;
    notifyListeners();
  }

  String _currentHeroId = '';
  String get currentHeroId => _currentHeroId;

  set currentHeroId( String newValue ) {
    _currentHeroId = newValue;
    notifyListeners();
  }

  Map<String, String> dominantColorCollection = {};

  Future<void> searchDominantColorByAlbumId({
    required String? albumId,
    required String appDirectory
  }) async {
    final fileImage = FileImage(File('$appDirectory/$albumId.jpg'));

    if( albumId == null  || !fileImage.file.existsSync() ) {
      _currentDominantColor = null;
      notifyListeners();
      return;
    }

    if( dominantColorCollection.containsKey(albumId) ) {
      final dominantColor = dominantColorCollection[albumId];
      _currentDominantColor = (dominantColor != null) ? Helpers.fromHex(dominantColor) : null;
      notifyListeners();
      return;
    }

    dominantColorCollection[albumId] = ((
      await PaletteGenerator.fromImageProvider( fileImage )
    ).dominantColor?.color ?? Colors.white).value.toRadixString(16);

    final dominantColor = dominantColorCollection[albumId];
    _currentDominantColor = (dominantColor != null) ? Helpers.fromHex(dominantColor) : null;
    UserPreferences().dominantColorCollection = dominantColorCollection;

    notifyListeners();
  }

}