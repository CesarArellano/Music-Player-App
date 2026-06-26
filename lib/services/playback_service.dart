import 'package:on_audio_query/on_audio_query.dart' show SongModel;

abstract interface class PlaybackService {
  /// The effective (shuffled or sequential) index order exposed by the player.
  List<int>? get effectiveIndices;

  /// Loads [songs] into the player and initialises playback state in all cubits.
  Future<void> loadPlaylist({
    required List<SongModel> songs,
    required int initialIndex,
    required String appDirectory,
    Duration? initialPosition,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position, {int? index});
  Future<void> setShuffleModeEnabled(bool enabled);
  Future<void> dispose();
}
