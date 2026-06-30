import 'package:focus_music_player/extensions/extensions.dart';
import 'package:music_query_selector/music_query_selector.dart';

extension Format on Duration {
  String getTimeString() {
    final minutes = inMinutes.remainder(Duration.minutesPerHour).toString();
    final seconds = inSeconds
      .remainder(Duration.secondsPerMinute)
      .toString()
      .padLeft(2, '0');
    return inHours > 0
      ? "$inHours:${minutes.padLeft(2, "0")}:$seconds"
      : "$minutes:$seconds";
  }
}

extension SongFormat on SongModel {
  String get songSubtitleText {
    String value = 'No Artist';
    
    if ((artist.value()).isNotEmpty) {
      value = '$artist';
    }

    return '$value • ${Duration(milliseconds: duration?.nonNullValue() ?? 0).getTimeString()}';
  }
}