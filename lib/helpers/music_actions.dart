import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_music_player/routes/app_router.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../data/repositories/preferences_repository.dart';
import '../screens/song_played_screen.dart';
import '../services/playback_service.dart';
import '../services/playlist_resolver.dart';

enum PlaylistType {
  songs,
  album,
  artist,
  genre,
  playlist,
  favorites,
}

/// Thin coordinator. All business logic lives in [PlaybackService],
/// [PlaylistResolverFactory], and [FavoritesService].
class MusicActions {
  static void initSongs(
    BuildContext context,
    SongModel song, {
    required String heroId,
  }) {
    final playbackService = audioPlayerHandler<PlaybackService>();
    final uiCubit = context.read<UICubit>();
    final playbackCubit = context.read<PlaybackStateCubit>();
    final audioControlCubit = context.read<AudioControlCubit>();
    final libraryState = context.read<LibraryCubit>().state;

    uiCubit.updateCurrentHeroId(heroId);

    final index = playbackCubit.state.currentPlaylist
        .indexWhere((s) => s.id == song.id);

    audioControlCubit.updateCurrentIndex(index);

    playbackService.loadPlaylist(
      songs: playbackCubit.state.currentPlaylist,
      initialIndex: index,
      appDirectory: libraryState.appDirectory,
      initialPosition: Duration(
        milliseconds: audioPlayerHandler<PreferencesRepository>().lastSongDuration,
      ),
    );
  }

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    PlaylistType type, {
    required String heroId,
    int? id,
    bool activateShuffle = false,
  }) {
    final playbackService = audioPlayerHandler<PlaybackService>();
    final uiCubit = context.read<UICubit>();
    final playbackCubit = context.read<PlaybackStateCubit>();
    final libraryState = context.read<LibraryCubit>().state;
    final favoritesState = context.read<FavoritesCubit>().state;

    uiCubit.updateCurrentHeroId(heroId);

    final prevLength = playbackCubit.state.currentPlaylist.length;
    final newPlaylist = PlaylistResolverFactory.resolve(
      type,
      libraryState,
      id: id,
      favoriteList: favoritesState.favoriteList,
    );
    playbackCubit.updateCurrentPlaylist(newPlaylist);

    final index = newPlaylist.indexWhere((s) => s.id == song.id);

    if (playbackCubit.state.songPlayed.id != song.id ||
        prevLength != newPlaylist.length) {
      playbackService.stop();
      playbackService.loadPlaylist(
        songs: newPlaylist,
        initialIndex: index,
        appDirectory: libraryState.appDirectory,
      );
    } else {
      playbackService.seek(Duration.zero);
    }

    playbackService.play();
    playbackService.setShuffleModeEnabled(activateShuffle);

    Navigator.push(
      context,
      AppRouter.slideUpRoute(
        SongPlayedScreen(
          playlistId: type == PlaylistType.playlist ? id : null,
          isPlaylist: type == PlaylistType.playlist,
        ),
      ),
    );
  }

  static Future<bool> deleteFile(File file) async {
    try {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted && await file.exists()) {
        await file.delete(recursive: true);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
