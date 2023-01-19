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
}