import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'audio_player_handler.dart';
import 'providers/audio_control_provider.dart';
import 'providers/music_player_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  setupAudioPlayerHandler();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider( create: ( _ ) => MusicPlayerProvider(), lazy: false ),
        ChangeNotifierProvider( create: ( _ ) => AudioControlProvider() ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music Player App',
        initialRoute: 'home',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}