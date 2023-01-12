import 'package:flutter/material.dart';

class UIProvider extends ChangeNotifier {
  
  int _currentIndex = 0;
  String _currentHeroId = '';
  
  int get currentIndex => _currentIndex;

  set currentIndex( int newIndex ) {
    _currentIndex = newIndex;
    notifyListeners();
  }

  String get currentHeroId => _currentHeroId;

  set currentHeroId( String newValue ) {
    _currentHeroId = newValue;
    notifyListeners();
  }
}