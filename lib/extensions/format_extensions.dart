import 'package:focus_music_player/extensions/extensions.dart';
import 'package:music_query_selector/music_query_selector.dart';

extension Format on Duration {
  String get timeString {
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

    return '$value • ${Duration(milliseconds: duration?.nonNullValue() ?? 0).timeString}';
  }

  String get audioFormatName {
    switch (fileExtension.toLowerCase()) {
      case 'mp3': return 'MPEG-1 Layer 3';
      case 'flac': return 'FLAC';
      case 'aac': return 'AAC';
      case 'ogg': return 'OGG Vorbis';
      case 'wav': return 'WAV (PCM)';
      case 'm4a': return 'MPEG-4 Audio';
      case 'opus': return 'Opus';
      case 'wma': return 'Windows Media Audio';
      default: return fileExtension.toUpperCase();
    }
  }
}

extension UnixTimestampFormat on int {
  String toTimestampString() {
    final dt = DateTime.fromMillisecondsSinceEpoch(this * 1000);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/${dt.year} $hour12:$minute $period';
  }
}

extension SongListDurationFormat on List<SongModel> {
  String totalDurationString() {
    final totalDurationMs = fold<int>(0, (acc, song) => acc + (song.duration ?? 0));
    return Duration(milliseconds: totalDurationMs).timeString;
  }
}

extension MillisecondsDurationFormat on int? {
  String toDurationString() =>
      Duration(milliseconds: this ?? 0).timeString;
}