import 'package:on_audio_query/on_audio_query.dart' show SongModel;

bool? nullExtensions;

extension IntNullExtension on int? {
  int value([int defaultValue = 0]) {
    return this ?? defaultValue;
  }
}

extension StringNullExtension on String? {
  String value([String defaultValue = '']) {
    return this ?? defaultValue;
  }

  String valueEmpty(String defaultValue) {
    if (this == null) return defaultValue;
    if (this!.isEmpty) return defaultValue;
    if (this!.trim() == '-') return defaultValue;
    return this!;
  }
}

extension NumNullExtensions on num? {
  num value([num defaultValue = 0.0]) {
    return this ?? defaultValue;
  }
}

extension DoubleNullExtensions on double? {
  double value([double defaultValue = 0.0]) {
    return this ?? defaultValue;
  }
}

extension BoolNullExtension on bool? {
  bool value([bool defaultValue = false]) {
    return this ?? defaultValue;
  }
}

// firstOrNull / firstOrNull2 removed — use Dart's built-in Iterable.firstOrNull

extension SongModelListExt on List<SongModel>? {
  List<SongModel> value() {
    if( this == null ) return [];
    return this!;
  }
}

extension SwappableList<E> on List<E> {
  void swap(int first, int second) {
    final temp = this[first];
    this[first] = this[second];
    this[second] = temp;
  }
}