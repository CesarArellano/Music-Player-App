class AudioControlState {
  const AudioControlState({
    this.currentIndex = 0,
    this.currentDuration = Duration.zero,
  });

  final int currentIndex;
  final Duration currentDuration;

  AudioControlState copyWith({
    int? currentIndex,
    Duration? currentDuration,
  }) {
    return AudioControlState(
      currentIndex: currentIndex ?? this.currentIndex,
      currentDuration: currentDuration ?? this.currentDuration,
    );
  }
}
