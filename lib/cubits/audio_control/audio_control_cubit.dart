import 'package:flutter_bloc/flutter_bloc.dart';

import 'audio_control_state.dart';

export 'audio_control_state.dart';

class AudioControlCubit extends Cubit<AudioControlState> {
  AudioControlCubit() : super(const AudioControlState());

  void updateCurrentIndex(int index) =>
      emit(state.copyWith(currentIndex: index));

  void updateCurrentDuration(Duration duration) =>
      emit(state.copyWith(currentDuration: duration));
}
