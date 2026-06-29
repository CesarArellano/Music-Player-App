import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_music_player/routes/app_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../data/repositories/preferences_repository.dart';
import '../extensions/extensions.dart';
import '../screens/song_played_screen.dart';
import '../services/playback_service.dart';
import '../services/playlist_resolver.dart';
import '../theme/app_theme.dart';

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

  static void showCurrentPlayList(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final playbackService = audioPlayerHandler<PlaybackService>();
    final playbackCubit = context.read<PlaybackStateCubit>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: playbackCubit.state.currentPlaylist.length,
        itemBuilder: (_, int i) {
          final effectiveIndices = playbackService.effectiveIndices;
          final song = playbackCubit.state.currentPlaylist[
              effectiveIndices != null ? effectiveIndices[i] : i];
          final audio = SongModel({
            '_id': song.id,
            'title': song.title,
            'artist': song.artist,
          });
          final isPlaying = playbackCubit.state.songPlayed.id == audio.id;
          final color = isPlaying ? AppTheme.accentColor : Colors.white;

          return ListTile(
            leading: Icon(Icons.music_note, color: color),
            title: Text(audio.title.value(), maxLines: 1,
                style: TextStyle(color: color)),
            subtitle: Text(audio.artist.valueEmpty('No Artists'), maxLines: 1,
                style: TextStyle(color: color)),
            onTap: () {
              audioPlayer.seek(Duration.zero, index: i);
              audioPlayer.play();
              Navigator.pop(ctx);
            },
          );
        },
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
