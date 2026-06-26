import 'package:on_audio_query/on_audio_query.dart';

class PlaybackState {
  PlaybackState({
    SongModel? songPlayed,
    this.currentPlaylist = const [],
    this.isShuffling = false,
  }) : songPlayed = songPlayed ?? SongModel({'_id': 0});

  final SongModel songPlayed;
  final List<SongModel> currentPlaylist;
  final bool isShuffling;

  PlaybackState copyWith({
    SongModel? songPlayed,
    List<SongModel>? currentPlaylist,
    bool? isShuffling,
  }) {
    return PlaybackState(
      songPlayed: songPlayed ?? this.songPlayed,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      isShuffling: isShuffling ?? this.isShuffling,
    );
  }
}
