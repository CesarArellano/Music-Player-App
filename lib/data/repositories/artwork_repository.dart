import 'dart:typed_data' show Uint8List;

abstract interface class ArtworkRepository {
  Future<Uint8List?> queryArtwork(int songId, {int size = 500});
  Future<int?> queryArtworkColor(int albumId);
}
