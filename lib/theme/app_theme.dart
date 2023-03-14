import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryColor = Color(0xFF003D71);
  static const Color accentColor = Colors.amber;
  static const Color lightTextColor = Colors.white54;

  static ThemeData lightTheme = ThemeData.light().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
    textTheme: Typography.whiteCupertino,
    scaffoldBackgroundColor: primaryColor,
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor
    ),
    iconTheme: const IconThemeData(
      color: lightTextColor
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0.0,
      backgroundColor: primaryColor,
      iconTheme: IconThemeData(color: lightTextColor)
    ),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: accentColor
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: lightTextColor,
      selectedLabelStyle: TextStyle(fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTheme.primaryColor
    )
  );
}