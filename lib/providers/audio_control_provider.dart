import 'package:flutter/material.dart';

class AudioControlProvider extends ChangeNotifier {
  Duration _current = const Duration(milliseconds: 0);

  Duration get current => _current;
  
  set current(Duration value) {
    _current= value;
    notifyListeners();
  }
  
}