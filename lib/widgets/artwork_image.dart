import 'package:flutter/material.dart';

import 'package:on_audio_query/on_audio_query.dart' show ArtworkFormatType, ArtworkType, QueryArtworkWidget;
class ArtworkImage extends StatelessWidget {
  const ArtworkImage({
    Key? key,
    required this.artworkId,
    this.size = 700,
    this.width = 200,
    this.height = 190,
    this.radius = BorderRadius.zero,
    this.type = ArtworkType.AUDIO,
    this.formatType = ArtworkFormatType.JPEG,
  }) : super(key: key);

  final int artworkId;
  final ArtworkType type;
  final ArtworkFormatType formatType;
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
      formatType: formatType,
      artworkBorder: radius,
      artworkWidth: width,
      artworkHeight: height,
      size: size,
      artworkFit: BoxFit.contain,
      nullArtworkWidget: Image.asset(
        'assets/images/artwork_not_available.jpg',
        width: height,
        height: height,
      ),
    );
  }
}