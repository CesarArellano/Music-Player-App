import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)
    )
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    appBarTheme: const AppBarTheme(
      titleTextStyle: TextStyle(color: Colors.white)
    )
  );
}