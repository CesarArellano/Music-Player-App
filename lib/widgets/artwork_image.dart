import 'package:flutter/material.dart';

import 'package:on_audio_query/on_audio_query.dart' show QueryArtworkWidget, ArtworkFormat, ArtworkType;
import 'package:on_audio_query/on_audio_query.dart';

class ArtworkImage extends StatelessWidget {
  const ArtworkImage({
    Key? key,
    required this.artworkId,
    this.size = 700,
    this.width = 200,
    this.height = 190,
    this.radius = BorderRadius.zero,
    this.type = ArtworkType.AUDIO,
    this.format = ArtworkFormat.JPEG,
  }) : super(key: key);

  final int artworkId;
  final ArtworkType type;
  final ArtworkFormat format;
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
      format: format,
      artworkBorder: radius,
      artworkWidth: width,
      artworkHeight: height,
      size: size,
      artworkFit: BoxFit.fitHeight,
      nullArtworkWidget: Image.asset(
        'assets/images/artwork_not_available.jpg',
        width: height,
        height: height,
      ),
    );
  }
}