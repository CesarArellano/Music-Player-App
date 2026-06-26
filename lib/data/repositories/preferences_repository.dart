abstract interface class PreferencesRepository {
  bool get isNotFirstTime;
  set isNotFirstTime(bool value);

  int get lastSongId;
  set lastSongId(int value);

  int get lastSongDuration;
  set lastSongDuration(int value);

  int get numberOfSongs;
  set numberOfSongs(int value);

  String get appDirectory;
  set appDirectory(String value);

  List<String> get favoriteSongList;
  set favoriteSongList(List<String> value);

  Map<String, String> get dominantColorCollection;
  set dominantColorCollection(Map<String, String> value);
}
