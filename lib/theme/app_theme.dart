import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF003D71);
  static const Color backgroundBase = Color(0xFF0C1D30);
  static const Color surfaceColor = Color(0xFF112240);
  static const Color accentColor = Colors.amber;
  static const Color lightTextColor = Colors.white54;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  static const double artworkRadius = 10.0;

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
    scaffoldBackgroundColor: Colors.transparent,

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
    ),

    iconTheme: const IconThemeData(color: lightTextColor),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: lightTextColor),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: accentColor,
      surface: surfaceColor,
    ),

    cardTheme: CardThemeData(
      color: surfaceColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(artworkRadius),
      ),
      clipBehavior: Clip.hardEdge,
    ),

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        color: lightTextColor,
        fontSize: 12,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: lightTextColor,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      elevation: 0,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 0.5,
    ),
  );
}
