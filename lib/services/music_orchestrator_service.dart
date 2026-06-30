import 'package:music_query_selector/music_query_selector.dart' show SongModel;

import '../audio_player_handler.dart';
import '../cubits/audio_control/audio_control_cubit.dart';
import '../cubits/favorites/favorites_cubit.dart';
import '../cubits/library/library_cubit.dart';
import '../cubits/playback_state/playback_state_cubit.dart';
import '../cubits/ui/ui_cubit.dart';
import '../data/repositories/preferences_repository.dart';
import '../models/playlist_type.dart';
import 'playback_service.dart';
import 'playlist_resolver.dart';

class MusicOrchestratorService {
  final PlaybackService _playbackService;
  final PlaybackStateCubit _playbackStateCubit;
  final AudioControlCubit _audioControlCubit;
  final UICubit _uiCubit;
  final LibraryCubit _libraryCubit;
  final FavoritesCubit _favoritesCubit;
  final PreferencesRepository _preferences;

  const MusicOrchestratorService({
    required this._playbackService,
    required this._playbackStateCubit,
    required this._audioControlCubit,
    required this._uiCubit,
    required this._libraryCubit,
    required this._favoritesCubit,
    required this._preferences,
  });

  /// Loads the current playlist into the player at the given [song]'s index,
  /// resuming from the last saved position. Does not start playback.
  void initSong(SongModel song, {required String heroId}) {
    _uiCubit.updateCurrentHeroId(heroId);

    final playlist = _playbackStateCubit.state.currentPlaylist;
    final index = playlist.indexWhere((s) => s.id == song.id);

    _audioControlCubit.updateCurrentIndex(index);

    _playbackService.loadPlaylist(
      songs: playlist,
      initialIndex: index,
      appDirectory: _libraryCubit.state.appDirectory,
      initialPosition: Duration(milliseconds: _preferences.lastSongDuration),
    );
  }

  /// Resolves the playlist for [type], loads it, and starts playback at [song].
  void playSong(
    SongModel song,
    PlaylistType type, {
    required String heroId,
    int? id,
    bool activateShuffle = false,
  }) {
    final libraryState = _libraryCubit.state;
    final prevLength = _playbackStateCubit.state.currentPlaylist.length;

    _uiCubit.updateCurrentHeroId(heroId);

    final newPlaylist = PlaylistResolverFactory.resolve(
      type,
      libraryState,
      id: id,
      favoriteList: _favoritesCubit.state.favoriteList,
    );
    _playbackStateCubit.updateCurrentPlaylist(newPlaylist);

    final index = newPlaylist.indexWhere((s) => s.id == song.id);

    if (_playbackStateCubit.state.songPlayed.id != song.id ||
        prevLength != newPlaylist.length) {
      _playbackService.stop();
      _playbackService.loadPlaylist(
        songs: newPlaylist,
        initialIndex: index,
        appDirectory: libraryState.appDirectory,
      );
    } else {
      _playbackService.seek(Duration.zero);
    }

    _playbackService.play();
    _playbackService.setShuffleModeEnabled(activateShuffle);
  }
}

MusicOrchestratorService buildMusicOrchestratorService() =>
    MusicOrchestratorService(
      playbackService: audioPlayerHandler<PlaybackService>(),
      playbackStateCubit: audioPlayerHandler<PlaybackStateCubit>(),
      audioControlCubit: audioPlayerHandler<AudioControlCubit>(),
      uiCubit: audioPlayerHandler<UICubit>(),
      libraryCubit: audioPlayerHandler<LibraryCubit>(),
      favoritesCubit: audioPlayerHandler<FavoritesCubit>(),
      preferences: audioPlayerHandler<PreferencesRepository>(),
    );
