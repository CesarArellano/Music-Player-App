import 'dart:io' show File;

import 'package:flutter/painting.dart' show FileImage;

class FileImageCache {
  final Map<String, FileImage> _cache = {};

  FileImage get(String path) => _cache[path] ??= FileImage(File(path));

  void evict(String path) {
    _cache.remove(path)?.evict();
  }

  void clear() {
    for (final image in _cache.values) {
      image.evict();
    }
    _cache.clear();
  }
}
