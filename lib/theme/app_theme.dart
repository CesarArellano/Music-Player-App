import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryColor = Color(0xFF0E3158);
  static const Color accentColor = Colors.amber;

  static ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography.whiteCupertino,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor
    ), 
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
    ).copyWith(secondary: accentColor),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF001F42),
      indicatorColor: Colors.blue.shade100,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle( fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white54 )
      )
    )
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.splashFactory,
    textTheme: Typography().white,
    brightness: Brightness.dark
  );
}