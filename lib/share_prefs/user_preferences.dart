import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static final  UserPreferences _instancia = UserPreferences._internal();
  
  factory UserPreferences() {
    return _instancia;
  }

  UserPreferences._internal();
  late SharedPreferences _prefs;

  initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // GET y SET del isFirstTime.
  bool get isFirstTime {
    return _prefs.getBool('isFirstTime') ?? false;
  }

  set isFirstTime(bool value) {
    _prefs.setBool('isFirstTime', value);
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
  
}