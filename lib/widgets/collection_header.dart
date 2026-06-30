import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:music_query_selector/music_query_selector.dart';

import 'artwork_file_image.dart';

class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    super.key,
    required this.artworkId,
    required this.imageFile,
    required this.title,
    required this.subtitle1,
    required this.subtitle2,
    this.artworkType = ArtworkType.ALBUM,
  });

  final int artworkId;
  final File imageFile;
  final String title;
  final String subtitle1;
  final String subtitle2;
  final ArtworkType artworkType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtworkFileImage(
            artworkId: artworkId,
            artworkType: artworkType,
            imageFile: imageFile,
            width: 175,
            height: 175,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w400, height: 0),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle1,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle2,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
