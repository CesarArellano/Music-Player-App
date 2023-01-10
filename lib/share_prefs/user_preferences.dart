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

  // GET y SET del favoriteSongList.
  List<String> get favoriteSongList {
    return _prefs.getStringList('favoriteSongList') ?? [];
  }

  set favoriteSongList(List<String> value) {
    _prefs.setStringList('favoriteSongList', value);
  }
}