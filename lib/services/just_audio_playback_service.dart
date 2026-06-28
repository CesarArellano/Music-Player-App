import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_query_selector/music_query_selector.dart' show SongModel;

import '../cubits/audio_control/audio_control_cubit.dart';
import '../cubits/playback_state/playback_state_cubit.dart';
import '../cubits/ui/ui_cubit.dart';
import '../data/repositories/preferences_repository.dart';
import '../extensions/extensions.dart';
import 'playback_service.dart';

class JustAudioPlaybackService implements PlaybackService {
  JustAudioPlaybackService({
    required AudioPlayer audioPlayer,
    required PlaybackStateCubit playbackStateCubit,
    required AudioControlCubit audioControlCubit,
    required this._uiCubit,
    required PreferencesRepository preferences,
  })  : _player = audioPlayer,
        _playbackCubit = playbackStateCubit,
        _audioCubit = audioControlCubit,
        _prefs = preferences {
    _subscribeToPosition();
    _subscribeToCurrentIndex();
  }

  final AudioPlayer _player;
  final PlaybackStateCubit _playbackCubit;
  final AudioControlCubit _audioCubit;
  final UICubit _uiCubit;
  final PreferencesRepository _prefs;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;

  @override
  List<int>? get effectiveIndices => _player.effectiveIndices;

  @override
  Future<void> loadPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
    required String appDirectory,
    Duration? initialPosition,
  }) {
    _player.setAudioSources(
      songs
          .where((song) => song.data != null)
          .map(
            (song) => AudioSource.file(
              song.data!,
              tag: MediaItem(
                id: song.id.value().toString(),
                title: song.title.value(),
                album: song.album,
                artist: song.artist,
                duration: Duration(milliseconds: song.duration.value()),
                genre: song.genre,
                artUri: Uri.file('$appDirectory/${song.albumId}.jpg'),
              ),
            ),
          )
          .toList(),
      initialIndex: initialIndex,
      initialPosition: initialPosition,
    );

    _audioCubit.updateCurrentIndex(initialIndex);
    final song = songs[initialIndex];
    _playbackCubit.updateSongPlayed(song);
    _prefs.lastSongId = song.id;
    _uiCubit.searchDominantColorByAlbumId(
      albumId: song.albumId.toString(),
    );

    return Future.value();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() {
    _prefs.lastSongDuration = _player.position.inMilliseconds;
    return _player.pause();
  }

  @override
  Future<void> stop() {
    _prefs.lastSongDuration = _player.position.inMilliseconds;
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position, {int? index}) =>
      _player.seek(position, index: index);

  @override
  Future<void> setShuffleModeEnabled(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  @override
  Future<void> dispose() async {
    await _positionSub?.cancel();
    await _indexSub?.cancel();
    await _player.dispose();
  }

  void _subscribeToPosition() {
    _positionSub = _player.positionStream.listen((duration) {
      _audioCubit.updateCurrentDuration(duration);
      // lastSongDuration is written on pause()/stop() only, not on every tick.
    });
  }

  void _subscribeToCurrentIndex() {
    _indexSub = _player.currentIndexStream.listen((currentIndex) {
      if (_playbackCubit.state.currentPlaylist.isEmpty) return;
      final index = currentIndex.value();
      _audioCubit.updateCurrentIndex(index);
      final song = _playbackCubit.state.currentPlaylist[index];
      _playbackCubit.updateSongPlayed(song);
      _prefs.lastSongId = song.id;
      _uiCubit.searchDominantColorByAlbumId(
        albumId: song.albumId.toString(),
      );
    });
  }
}
