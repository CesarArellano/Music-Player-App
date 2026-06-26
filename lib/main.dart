import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_player_handler.dart';
import 'cubits/cubits.dart';
import 'routes/app_router.dart';
import 'services/snackbar_service.dart';
import 'widgets/app_background.dart';
import 'share_prefs/user_preferences.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserPreferences().initPrefs();
  setupAudioHandlers();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  final audioControlCubit = AudioControlCubit();
  final playbackStateCubit = PlaybackStateCubit();
  final favoritesCubit = FavoritesCubit();
  final uiCubit = UICubit();

  // LibraryCubit starts loading songs immediately in its constructor.
  // onSongsLoaded wires FavoritesCubit so it can decode persisted IDs.
  final libraryCubit = LibraryCubit(
    onSongsLoaded: favoritesCubit.initFavorites,
  );

  setupServiceLayer(
    libraryCubit: libraryCubit,
    playbackStateCubit: playbackStateCubit,
    favoritesCubit: favoritesCubit,
    audioControlCubit: audioControlCubit,
    uiCubit: uiCubit,
  );

  runApp(MyApp(
    libraryCubit: libraryCubit,
    playbackStateCubit: playbackStateCubit,
    favoritesCubit: favoritesCubit,
    audioControlCubit: audioControlCubit,
    uiCubit: uiCubit,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.libraryCubit,
    required this.playbackStateCubit,
    required this.favoritesCubit,
    required this.audioControlCubit,
    required this.uiCubit,
  });

  final LibraryCubit libraryCubit;
  final PlaybackStateCubit playbackStateCubit;
  final FavoritesCubit favoritesCubit;
  final AudioControlCubit audioControlCubit;
  final UICubit uiCubit;

  @override
  Widget build(BuildContext context) {
    final snackbarService = audioPlayerHandler.get<SnackbarService>();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: libraryCubit),
        BlocProvider.value(value: playbackStateCubit),
        BlocProvider.value(value: favoritesCubit),
        BlocProvider.value(value: audioControlCubit),
        BlocProvider.value(value: uiCubit),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Focus Music Player',
        initialRoute: 'home',
        scaffoldMessengerKey: snackbarService.scaffoldMessengerKey,
        theme: AppTheme.darkTheme,
        routes: AppRouter.routes,
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) => AppBackground(child: child!),
      ),
    );
  }
}
