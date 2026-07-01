import 'package:music_query_selector/music_query_selector.dart';

class PlaybackState {
  PlaybackState({
    SongModel? songPlayed,
    this.currentPlaylist = const [],
    this.isShuffling = false,
    this.isPlaying = false,
  }) : songPlayed = songPlayed ?? SongModel({'_id': 0});

  final SongModel songPlayed;
  final List<SongModel> currentPlaylist;
  final bool isShuffling;
  final bool isPlaying;

  PlaybackState copyWith({
    SongModel? songPlayed,
    List<SongModel>? currentPlaylist,
    bool? isShuffling,
    bool? isPlaying,
  }) {
    return PlaybackState(
      songPlayed: songPlayed ?? this.songPlayed,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      isShuffling: isShuffling ?? this.isShuffling,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
