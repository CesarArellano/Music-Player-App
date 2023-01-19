import 'package:flutter/material.dart';


class AudioControlProvider extends ChangeNotifier {

  int _currentIndex = 0;
  Duration _currentDuration = const Duration(milliseconds: 0);
  
  int get currentIndex => _currentIndex;

  set currentIndex(int value) {
    _currentIndex = value;
    notifyListeners();
  }

  Duration get currentDuration => _currentDuration;
  
  set currentDuration(Duration value) {
    _currentDuration = value;
    notifyListeners();
  }
}