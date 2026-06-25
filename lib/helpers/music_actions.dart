import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../models/artist_content_model.dart';
import '../screens/song_played_screen.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';


enum PlaylistType {
  songs,
  album,
  artist,
  genre,
  playlist,
  favorites,
}

class MusicActions {

  static List<SongModel> getPlaylistType({
    int? id,
    required PlaylistType type,
    required MusicPlayerState musicPlayerState,
  }) {
    final map = {
      PlaylistType.songs: musicPlayerState.songList,
      PlaylistType.album: musicPlayerState.albumCollection[id].value(),
      PlaylistType.artist: (musicPlayerState.artistCollection[id] ?? ArtistContentModel()).songs,
      PlaylistType.playlist: musicPlayerState.playlistCollection[id].value(),
      PlaylistType.genre: musicPlayerState.genreCollection[id].value(),
      PlaylistType.favorites: musicPlayerState.favoriteList,
    };
    return map[type] ?? musicPlayerState.songList;
  }

  static void initSongs(
    BuildContext context,
    SongModel song, {
    required String heroId,
  }) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiCubit = context.read<UICubit>();
    final musicPlayerCubit = context.read<MusicPlayerCubit>();
    final audioControlCubit = context.read<AudioControlCubit>();

    uiCubit.updateCurrentHeroId(heroId);

    final index = musicPlayerCubit.state.currentPlaylist
        .indexWhere((s) => s.id == song.id);

    audioControlCubit.updateCurrentIndex(index);

    openAudios(
      index: index,
      audioPlayer: audioPlayer,
      audioControlCubit: audioControlCubit,
      musicPlayerCubit: musicPlayerCubit,
      uiCubit: uiCubit,
      seek: Duration(milliseconds: UserPreferences().lastSongDuration),
    );
  }

  static void initStreams(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiCubit = context.read<UICubit>();
    final musicPlayerCubit = context.read<MusicPlayerCubit>();
    final audioControlCubit = context.read<AudioControlCubit>();

    musicPlayerCubit.updateCurrentPlaylist(musicPlayerCubit.state.songList);

    audioPlayer.positionStream.listen((duration) {
      audioControlCubit.updateCurrentDuration(duration);
      UserPreferences().lastSongDuration = duration.inMilliseconds;
    });

    audioPlayer.currentIndexStream.listen((currentIndex) {
      if (musicPlayerCubit.state.currentPlaylist.isEmpty) return;

      final index = currentIndex.value();
      audioControlCubit.updateCurrentIndex(index);
      final song = musicPlayerCubit.state.currentPlaylist[index];
      musicPlayerCubit.updateSongPlayed(song);
      UserPreferences().lastSongId = song.id;

      uiCubit.searchDominantColorByAlbumId(
        albumId: song.albumId.toString(),
        appDirectory: musicPlayerCubit.state.appDirectory,
      );
    });
  }

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    PlaylistType type, {
    required String heroId,
    int? id,
    bool activateShuffle = false,
  }) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final uiCubit = context.read<UICubit>();
    final musicPlayerCubit = context.read<MusicPlayerCubit>();
    final audioControlCubit = context.read<AudioControlCubit>();

    uiCubit.updateCurrentHeroId(heroId);

    final prevLength = musicPlayerCubit.state.currentPlaylist.length;

    final newPlaylist = getPlaylistType(
      id: id,
      type: type,
      musicPlayerState: musicPlayerCubit.state,
    );
    musicPlayerCubit.updateCurrentPlaylist(newPlaylist);

    final index = newPlaylist.indexWhere((s) => s.id == song.id);

    if (musicPlayerCubit.state.songPlayed.id != song.id ||
        prevLength != newPlaylist.length) {
      audioPlayer.stop();
      openAudios(
        index: index,
        audioPlayer: audioPlayer,
        audioControlCubit: audioControlCubit,
        musicPlayerCubit: musicPlayerCubit,
        uiCubit: uiCubit,
      );
    } else {
      audioPlayer.seek(Duration.zero);
    }

    audioPlayer.play();
    audioPlayer.setShuffleModeEnabled(activateShuffle);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayedScreen(
          playlistId: type == PlaylistType.playlist ? id : null,
          isPlaylist: type == PlaylistType.playlist,
        ),
      ),
    );
  }

  static void showCurrentPlayList(BuildContext context) {
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerCubit = context.read<MusicPlayerCubit>();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => ListView.builder(
        shrinkWrap: true,
        itemCount: musicPlayerCubit.state.currentPlaylist.length,
        itemBuilder: (_, int i) {
          final song = musicPlayerCubit.state.currentPlaylist[
              audioPlayer.effectiveIndices[i]];
          final audio = SongModel({
            '_id': song.id,
            'title': song.title,
            'artist': song.artist,
          });
          final isPlaying = musicPlayerCubit.state.songPlayed.id == audio.id;
          final color = isPlaying ? AppTheme.accentColor : Colors.white;

          return ListTile(
            leading: Icon(Icons.music_note, color: color),
            title: Text(audio.title.value(), maxLines: 1, style: TextStyle(color: color)),
            subtitle: Text(audio.artist.valueEmpty('No Artists'), maxLines: 1, style: TextStyle(color: color)),
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

  static Future<bool> createArtwork(File imageTempFile, int songId) async {
    final bytes = await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500);
    if (bytes != null) {
      await imageTempFile.writeAsBytes(bytes);
      return true;
    }
    return false;
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

  static void openAudios({
    required int index,
    required AudioPlayer audioPlayer,
    required AudioControlCubit audioControlCubit,
    required MusicPlayerCubit musicPlayerCubit,
    required UICubit uiCubit,
    Duration? seek,
  }) {
    audioPlayer.setAudioSources(
      musicPlayerCubit.state.currentPlaylist.map((song) => AudioSource.file(
        song.data,
        tag: MediaItem(
          id: song.id.value().toString(),
          title: song.title.value(),
          album: song.album,
          artist: song.artist,
          duration: Duration(milliseconds: song.duration.value()),
          genre: song.genre,
          artUri: Uri.file(
              '${musicPlayerCubit.state.appDirectory}/${song.albumId}.jpg'),
        ),
      )).toList(),
      initialIndex: index,
      initialPosition: seek,
    );

    audioControlCubit.updateCurrentIndex(index);
    final song = musicPlayerCubit.state.currentPlaylist[index];
    musicPlayerCubit.updateSongPlayed(song);
    UserPreferences().lastSongId = song.id;

    uiCubit.searchDominantColorByAlbumId(
      albumId: song.albumId.toString(),
      appDirectory: musicPlayerCubit.state.appDirectory,
    );
  }
}
