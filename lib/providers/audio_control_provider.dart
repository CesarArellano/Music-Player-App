import 'package:flutter/material.dart';

class AudioControlProvider extends ChangeNotifier {

  int _currentIndex = 0;
  Duration _current = const Duration(milliseconds: 0);
  
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  Duration get current => _current;
  
  set current(Duration value) {
    _current= value;
    notifyListeners();
  }
  
}