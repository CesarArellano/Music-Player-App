import 'package:flutter/material.dart';
import 'package:focus_music_player/screens/screens.dart';

class AppRouter {
  static final Map<String, Widget Function(BuildContext)> routes = {
    'home': ( _ ) => const HomeScreen(),
  };

  static Route<dynamic> onGenerateRoute( RouteSettings settings ) {
    return MaterialPageRoute(
      builder: ( _ ) => const HomeScreen()
    );
  }
}