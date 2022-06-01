import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    brightness: Brightness.dark
  );
}