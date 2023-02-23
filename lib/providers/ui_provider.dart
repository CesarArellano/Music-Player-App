import 'package:flutter/material.dart';

class UIProvider extends ChangeNotifier {
  
  String _currentHeroId = '';
  String get currentHeroId => _currentHeroId;

  set currentHeroId( String newValue ) {
    _currentHeroId = newValue;
    notifyListeners();
  }
}