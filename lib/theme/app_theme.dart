import 'package:flutter/material.dart';

class AppTheme {

  static const Color primaryColor = Color(0xFF104674);
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
      secondary: Colors.white
    ).copyWith(secondary: accentColor),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: primaryColor,
      indicatorColor: Colors.blue.shade200,
      labelTextStyle: MaterialStateProperty.all(
        const TextStyle( fontSize: 12, color: lightTextColor)
      )
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: primaryColor,
      selectedItemColor: Colors.white,
      unselectedItemColor: lightTextColor,
      selectedLabelStyle: TextStyle(fontSize: 12),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTheme.primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        )
      ),
    )
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    useMaterial3: true,
    splashFactory: InkSparkle.constantTurbulenceSeedSplashFactory,
    textTheme: Typography().white,
    brightness: Brightness.dark
  );
}