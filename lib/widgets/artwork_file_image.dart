import 'dart:io' show File;

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
          child: _ImageWithBorder(
            radius: radius,
            imageFile: imageFile,
            width: width, 
            height: height,
            artworkId: artworkId,
            artworkType: artworkType
          ),
        )
        : _ImageWithBorder(
            radius: radius,
            imageFile: imageFile,
            width: width, 
            height: height,
            artworkId: artworkId,
            artworkType: artworkType
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

class _ImageWithBorder extends StatelessWidget {
  const _ImageWithBorder({
    Key? key,
    required this.radius,
    required this.imageFile,
    required this.width,
    required this.height,
    required this.artworkId,
    required this.artworkType,
  }) : super(key: key);

  final BorderRadius radius;
  final File? imageFile;
  final double width;
  final double height;
  final int artworkId;
  final ArtworkType artworkType;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        imageFile!,
        width: width,
        height: height,
        fit: BoxFit.cover,
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
    );
  }
}