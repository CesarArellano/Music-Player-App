import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;

class ArtworkFileImage extends StatelessWidget {
  const ArtworkFileImage({
    super.key,
    required this.artworkId,
    this.imageFile,
    this.artworkType = ArtworkType.AUDIO,
    this.width = 55,
    this.height = 55,
  });

  final ArtworkType artworkType;
  final int artworkId;
  final File? imageFile;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return (imageFile ?? File('')).existsSync() 
      ? ClipRRect(
        borderRadius: BorderRadius.circular(2.5),
        child: Image.file(
          imageFile!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
        ),
      )
      : ArtworkImage(
        artworkId: artworkId,
        type: artworkType,
        width: width,
        height: height,
        size: 250,
        radius: BorderRadius.circular(2.5),
      );
  }
}