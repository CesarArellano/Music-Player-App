import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final  UserPreferences _instancia = UserPreferences._internal();
  
  factory UserPreferences() {
    return _instancia;
  }

  UserPreferences._internal();
  late SharedPreferences _prefs;

  Future<void> initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // GET y SET del isNotFirstTime.
  bool get isNotFirstTime {
    return _prefs.getBool('isNotFirstTime') ?? false;
  }

  set isNotFirstTime(bool value) {
    _prefs.setBool('isNotFirstTime', value);
  }

  // GET y SET del favoriteSongList.
  List<String> get favoriteSongList {
    return _prefs.getStringList('favoriteSongList') ?? [];
  }

  set favoriteSongList(List<String> value) {
    _prefs.setStringList('favoriteSongList', value);
  }

  // GET y SET LastSongId.
  int get lastSongId {
    return _prefs.getInt('lastSongId') ?? 0;
  }

  set lastSongId(int value) {
    _prefs.setInt('lastSongId', value);
  }

  // GET y SET lastSongDuration.
  int get lastSongDuration {
    return _prefs.getInt('lastSongDuration') ?? 0;
  }

  set lastSongDuration(int value) {
    _prefs.setInt('lastSongDuration', value);
  }

  // GET y SET numberOfSongs.
  int get numberOfSongs {
    return _prefs.getInt('numberOfSongs') ?? 0;
  }

  set numberOfSongs(int value) {
    _prefs.setInt('numberOfSongs', value);
  }
  

  // GET y SET appDirectory.
  String get appDirectory {
    return _prefs.getString('appDirectory') ?? '';
  }

  set appDirectory(String value) {
    _prefs.setString('appDirectory', value);
  }
  
  // GET y SET appDirectory.
  Map<String, String> get dominantColorCollection {
    final Map<String, String> dominantColorCollection = Map<String,String>.from( 
      json.decode(_prefs.getString('dominantColorCollection') ?? '{}')
    );
    return dominantColorCollection;
  }

  set dominantColorCollection(Map<String, String> value) {
    _prefs.setString('dominantColorCollection', json.encode(value));
  }
}