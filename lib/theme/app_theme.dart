import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    textTheme: Typography().white,
  );

  static ThemeData darkTheme = ThemeData.dark();
}