import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import 'playback_state.dart';

export 'playback_state.dart';

class PlaybackStateCubit extends Cubit<PlaybackState> {
  PlaybackStateCubit() : super(PlaybackState());

  void clearSongPlayed() =>
      emit(PlaybackState(currentPlaylist: state.currentPlaylist, isShuffling: state.isShuffling));

  void updateSongPlayed(SongModel song) =>
      emit(state.copyWith(songPlayed: song));

  void updateCurrentPlaylist(List<SongModel> playlist) =>
      emit(state.copyWith(currentPlaylist: playlist));

  void updateIsShuffling(bool value) =>
      emit(state.copyWith(isShuffling: value));

  void updateIsPlaying(bool value) =>
      emit(state.copyWith(isPlaying: value));
}
