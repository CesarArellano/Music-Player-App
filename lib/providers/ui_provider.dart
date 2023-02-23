import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

class UIProvider extends ChangeNotifier {
  
  PaletteGenerator? _paletteGenerator;

  PaletteGenerator? get paletteGenerator => _paletteGenerator;

  set paletteGenerator(PaletteGenerator? newValue) {
    _paletteGenerator = newValue;
    notifyListeners();
  }

  String _currentHeroId = '';
  String get currentHeroId => _currentHeroId;

  set currentHeroId( String newValue ) {
    _currentHeroId = newValue;
    notifyListeners();
  }
}