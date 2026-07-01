import 'package:flutter/services.dart' show Uint8List;
import 'package:music_query_selector/music_query_selector.dart';

class TagData {
  const TagData({
    required this.title,
    required this.album,
    required this.artist,
    required this.albumArtist,
    required this.composer,
    required this.genre,
    required this.year,
    required this.track,
    this.artworkBytes,
  });

  final String title;
  final String album;
  final String artist;
  final String albumArtist;
  final String composer;
  final String genre;
  final String year;
  final String track;
  final Uint8List? artworkBytes;
}

/// Reads and writes audio metadata tags via the [MusicQuerySelector] plugin
/// (native JAudioTagger implementation on Android).
class TagEditorService {
  TagEditorService([MusicQuerySelector? selector])
      : _selector = selector ?? MusicQuerySelector();

  final MusicQuerySelector _selector;

  Future<TagData> readTags(String path) async {
    final map = await _selector.readTags(path);
    return TagData(
      title: map['title'] as String? ?? '',
      album: map['album'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      albumArtist: map['albumArtist'] as String? ?? '',
      composer: map['composer'] as String? ?? '',
      genre: map['genre'] as String? ?? '',
      year: map['year'] as String? ?? '',
      track: map['track'] as String? ?? '',
      artworkBytes: map['artworkBytes'] as Uint8List?,
    );
  }

  Future<void> writeTags(String path, TagData data) async {
    await _selector.writeTags(path, {
      'title': data.title,
      'album': data.album,
      'artist': data.artist,
      'albumArtist': data.albumArtist,
      'composer': data.composer,
      'genre': data.genre,
      'year': data.year,
      'track': data.track,
      if (data.artworkBytes != null) 'artworkBytes': data.artworkBytes,
    });
  }
}
