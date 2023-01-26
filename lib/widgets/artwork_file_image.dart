import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/widgets/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;

class ArtworkFileImage extends StatelessWidget {
  const ArtworkFileImage({
    super.key,
    required this.artworkId,
    this.imageFile,
    this.artworkType = ArtworkType.AUDIO,
    this.width = 55,
    this.height = 55,
    this.tag
  });

  final ArtworkType artworkType;
  final int artworkId;
  final File? imageFile;
  final double width;
  final double height;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(5);

    return (imageFile ?? File('')).existsSync() 
      ? tag != null
        ? Hero(
          tag: tag!,
          child: ClipRRect(
            borderRadius: radius,
            child: Image.file(
              imageFile!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                return ArtworkImage(
                  artworkId: artworkId,
                  type: artworkType,
                  width: width,
                  height: height,
                  size: 250,
                  radius: BorderRadius.circular(4),
                );
              },
            ),
          ),
        )
        : ClipRRect(
          borderRadius: radius,
          child: Image.file(
            imageFile!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return ArtworkImage(
                artworkId: artworkId,
                type: artworkType,
                width: width,
                height: height,
                size: 250,
                radius: radius,
              );
            },
          ),
        )
    : ArtworkImage(
      artworkId: artworkId,
      type: artworkType,
      width: width,
      height: height,
      size: 250,
      radius: radius,
    );
  }
}