import 'package:flutter/material.dart';

class AppTheme {

  static const Color accentColor = Colors.amber;

  static ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor
    ), 
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
    ).copyWith(secondary: accentColor)
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    brightness: Brightness.dark
  );
}