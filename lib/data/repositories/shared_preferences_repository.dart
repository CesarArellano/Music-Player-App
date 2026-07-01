import 'dart:convert';
import 'dart:isolate';

import '../../share_prefs/user_preferences.dart';
import 'preferences_repository.dart';

class SharedPreferencesRepository implements PreferencesRepository {
  SharedPreferencesRepository(this._prefs);

  final UserPreferences _prefs;

  @override
  bool get isNotFirstTime => _prefs.isNotFirstTime;
  @override
  set isNotFirstTime(bool value) => _prefs.isNotFirstTime = value;

  @override
  int get lastSongId => _prefs.lastSongId;
  @override
  set lastSongId(int value) => _prefs.lastSongId = value;

  @override
  int get lastSongDuration => _prefs.lastSongDuration;
  @override
  set lastSongDuration(int value) => _prefs.lastSongDuration = value;

  @override
  int get numberOfSongs => _prefs.numberOfSongs;
  @override
  set numberOfSongs(int value) => _prefs.numberOfSongs = value;

  @override
  String get appDirectory => _prefs.appDirectory;
  @override
  set appDirectory(String value) => _prefs.appDirectory = value;

  @override
  List<String> get favoriteSongList => _prefs.favoriteSongList;
  @override
  set favoriteSongList(List<String> value) => _prefs.favoriteSongList = value;

  Map<String, String>? _colorCache;

  @override
  Map<String, String> get dominantColorCollection =>
      _colorCache ??= _prefs.dominantColorCollection;

  @override
  set dominantColorCollection(Map<String, String> value) {
    _colorCache = value;
    Isolate.run(() => json.encode(value))
        .then((encoded) => _prefs.setRawDominantColor(encoded));
  }
}
