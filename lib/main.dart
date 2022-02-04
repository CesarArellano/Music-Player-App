import 'package:flutter/material.dart';

import 'package:music_player_app/routes/app_router.dart';
import 'package:music_player_app/theme/app_theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      initialRoute: 'home',
      theme: AppTheme.lightTheme,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}