import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_music_player/helpers/helpers.dart';
import 'package:focus_music_player/share_prefs/user_preferences.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_player_handler.dart';
import 'cubits/cubits.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = UserPreferences();
  await prefs.initPrefs();
  setupAudioHandlers();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MusicPlayerCubit()),
        BlocProvider(create: (_) => AudioControlCubit()),
        BlocProvider(create: (_) => UICubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Focus Music Player',
        initialRoute: 'home',
        scaffoldMessengerKey: Helpers.scaffoldKey,
        theme: AppTheme.lightTheme,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
