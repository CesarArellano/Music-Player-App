import 'dart:io';

import 'package:flutter/material.dart' show Color, Colors, ChangeNotifier, FileImage, AnimationController;
import 'package:palette_generator/palette_generator.dart';

class UIProvider extends ChangeNotifier {
  
  AnimationController? _animationController;

  AnimationController? get animationController => _animationController;

  set animationController( AnimationController? newValue ) {
    _animationController = newValue;
    notifyListeners();
  }

  Color? _currentDominantColor;
  Color get currentDominantColor => _currentDominantColor ?? Colors.black;
  Color get songPlayedThemeColor => ( currentDominantColor.computeLuminance() < 0.4 ) ? Colors.white : Colors.black;

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

  Map<int, Color> dominantColorCollection = {};

  Future<void> searchDominantColorByAlbumId({
    required int? albumId,
    required String appDirectory
  }) async {
    final fileImage = FileImage(File('$appDirectory/$albumId.jpg'));

    if( albumId == null  || !fileImage.file.existsSync() ) {
      _currentDominantColor = null;
      notifyListeners();
      return;
    }

    if( dominantColorCollection.containsKey(albumId) ) {
      _currentDominantColor = dominantColorCollection[albumId];
      notifyListeners();
      return;
    }

    dominantColorCollection[albumId] = (
      await PaletteGenerator.fromImageProvider( fileImage )
    ).dominantColor?.color ?? Colors.white;

    _currentDominantColor = dominantColorCollection[albumId];

    notifyListeners();
  }

}