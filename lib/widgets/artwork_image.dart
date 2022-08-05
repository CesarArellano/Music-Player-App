import 'package:flutter/material.dart';

import 'package:on_audio_query/on_audio_query.dart' show ArtworkFormat, ArtworkType, QueryArtworkWidget;
class ArtworkImage extends StatelessWidget {
  const ArtworkImage({
    Key? key,
    required this.artworkId,
    this.size = 700,
    this.width = 200,
    this.height = 190,
    this.radius = BorderRadius.zero,
    this.type = ArtworkType.AUDIO,
    this.formatType = ArtworkFormat.JPEG,
  }) : super(key: key);

  final int artworkId;
  final ArtworkType type;
  final ArtworkFormat formatType;
  final double width;
  final double height;
  final int size;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      keepOldArtwork: true,
      id: artworkId,
      type: type,
      format: formatType,
      artworkBorder: radius,
      artworkWidth: width,
      artworkHeight: height,
      size: size,
      artworkFit: BoxFit.contain,
      nullArtworkWidget: Container(
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(2.5)
        ),
        width: height,
        height: height,
        child:  Icon(Icons.music_note_rounded, color: Colors.white54, size: height * 0.5),
      ),
    );
  }
}