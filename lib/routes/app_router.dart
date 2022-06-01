import 'package:flutter/material.dart';
import 'package:music_player_app/screens/screens.dart';

class AppRouter {
  static final Map<String, Widget Function(BuildContext)> routes = {
    'home': ( _ ) => HomeScreen(),
  };

  static Route<dynamic> onGenerateRoute( RouteSettings settings ) {
    return MaterialPageRoute(
      builder: ( _ ) => HomeScreen()
    );
  }
}