import 'package:flutter/material.dart';
import 'package:music_player_app/providers/music_player_provider.dart';

import 'package:music_player_app/routes/app_router.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider( create: ( _ ) => MusicPlayerProvider(), lazy: false ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music Player App',
        initialRoute: 'home',
        theme: AppTheme.lightTheme,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}