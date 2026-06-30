import 'package:music_query_selector/music_query_selector.dart' show SongModel;

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

  /// Removes [song] from the live queue. Removing the currently-playing song
  /// makes playback advance to the next track seamlessly; removing the last
  /// remaining song stops playback.
  Future<void> removeFromQueue(SongModel song);

  /// Moves the song at [oldIndex] to [newIndex] in the live queue without
  /// reloading the playlist.
  Future<void> moveInQueue(int oldIndex, int newIndex);

  Future<void> dispose();
}
