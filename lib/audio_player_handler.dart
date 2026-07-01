import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_query_selector/music_query_selector.dart';

import 'cubits/audio_control/audio_control_cubit.dart';
import 'cubits/favorites/favorites_cubit.dart';
import 'cubits/library/library_cubit.dart';
import 'cubits/playback_state/playback_state_cubit.dart';
import 'cubits/ui/ui_cubit.dart';
import 'data/cache/file_image_cache.dart';
import 'data/repositories/audio_repository.dart';
import 'data/repositories/artwork_repository.dart';
import 'data/repositories/on_audio_query_repository.dart';
import 'data/repositories/preferences_repository.dart';
import 'data/repositories/shared_preferences_repository.dart';
import 'data/services/artwork_cache_service.dart';
import 'services/favorites_service.dart';
import 'services/file_management_service.dart';
import 'services/just_audio_playback_service.dart';
import 'services/music_orchestrator_service.dart';
import 'services/playback_service.dart';
import 'services/snackbar_service.dart';
import 'share_prefs/user_preferences.dart';

GetIt audioPlayerHandler = GetIt.instance;

void setupAudioHandlers() {
  audioPlayerHandler.registerSingleton<FileImageCache>(FileImageCache());
  audioPlayerHandler.registerLazySingleton(() => AudioPlayer());
  audioPlayerHandler.registerLazySingleton(() => MusicQuerySelector());
  audioPlayerHandler.registerSingleton<SnackbarService>(SnackbarService());

  audioPlayerHandler.registerLazySingleton<PreferencesRepository>(
    () => SharedPreferencesRepository(UserPreferences()),
  );

  audioPlayerHandler.registerLazySingleton<AudioRepository>(
    () => MusicQuerySelectorRepository(audioPlayerHandler<MusicQuerySelector>()),
  );

  audioPlayerHandler.registerLazySingleton<ArtworkRepository>(
    () => audioPlayerHandler<AudioRepository>() as ArtworkRepository,
  );

  audioPlayerHandler.registerLazySingleton<ArtworkCacheService>(
    () => ArtworkCacheService(
      artworkRepository: audioPlayerHandler<ArtworkRepository>(),
      preferences: audioPlayerHandler<PreferencesRepository>(),
    ),
  );

  audioPlayerHandler.registerLazySingleton<FileManagementService>(
    () => const FileManagementService(),
  );
}

/// Called from main() after [setupAudioHandlers] and after cubits are created.
/// Registers cubit singletons so services can reference them without BuildContext.
void setupServiceLayer({
  required LibraryCubit libraryCubit,
  required PlaybackStateCubit playbackStateCubit,
  required FavoritesCubit favoritesCubit,
  required AudioControlCubit audioControlCubit,
  required UICubit uiCubit,
}) {
  audioPlayerHandler.registerSingleton<LibraryCubit>(libraryCubit);
  audioPlayerHandler.registerSingleton<PlaybackStateCubit>(playbackStateCubit);
  audioPlayerHandler.registerSingleton<FavoritesCubit>(favoritesCubit);
  audioPlayerHandler.registerSingleton<AudioControlCubit>(audioControlCubit);
  audioPlayerHandler.registerSingleton<UICubit>(uiCubit);

  audioPlayerHandler.registerSingleton<FavoritesService>(
    FavoritesService(
      favoritesCubit: favoritesCubit,
      preferences: audioPlayerHandler<PreferencesRepository>(),
    ),
  );

  // Eagerly creating PlaybackService starts the positionStream and
  // currentIndexStream subscriptions immediately at app startup.
  audioPlayerHandler.registerSingleton<PlaybackService>(
    JustAudioPlaybackService(
      audioPlayer: audioPlayerHandler<AudioPlayer>(),
      playbackStateCubit: playbackStateCubit,
      audioControlCubit: audioControlCubit,
      preferences: audioPlayerHandler<PreferencesRepository>(),
    ),
  );

  audioPlayerHandler.registerSingleton<MusicOrchestratorService>(
    buildMusicOrchestratorService(),
  );
}
