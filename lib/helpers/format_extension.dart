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