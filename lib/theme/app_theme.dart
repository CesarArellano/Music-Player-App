import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    textTheme: Typography().white,
    splashFactory: InkRipple.splashFactory,
    splashColor: Colors.white10
  );

  static ThemeData darkTheme = ThemeData.dark();
}