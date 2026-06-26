import 'dart:io' show File;

import 'package:on_audio_query/on_audio_query.dart' show SongModel;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory;

import '../repositories/audio_repository.dart';
import '../repositories/preferences_repository.dart';

class ArtworkCacheService {
  ArtworkCacheService({
    required AudioRepository audioRepository,
    required PreferencesRepository preferences,
  })  : _audio = audioRepository,
        _prefs = preferences;

  final AudioRepository _audio;
  final PreferencesRepository _prefs;

  Future<String> resolveAppDirectory() async {
    if (_prefs.isNotFirstTime) return _prefs.appDirectory;
    final dir = (await getApplicationDocumentsDirectory()).path;
    _prefs.appDirectory = dir;
    return dir;
  }

  /// Writes missing artwork files to [appDirectory].
  /// Skips entirely if [force] is false and song count hasn't changed.
  Future<void> buildArtworkCache({
    required List<SongModel> songs,
    required String appDirectory,
    required bool force,
  }) async {
    if (!force && _prefs.numberOfSongs == songs.length) return;

    for (final song in songs) {
      final file = File('$appDirectory/${song.albumId}.jpg');
      if (file.existsSync()) continue;
      final bytes = await _audio.queryArtwork(song.id);
      if (bytes != null) await file.writeAsBytes(bytes);
    }

    _prefs.isNotFirstTime = true;
  }

  Future<bool> createSingleArtwork(File target, int songId) async {
    try {
      final bytes = await _audio.queryArtwork(songId);
      if (bytes == null) return false;
      await target.writeAsBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteFile(File file) async {
    try {
      if (!file.existsSync()) return false;
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
