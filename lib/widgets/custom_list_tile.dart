import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:focus_music_player/widgets/artwork_file_image.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;

import '../theme/app_theme.dart';

class CustomListTile extends StatelessWidget {
  
  const CustomListTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.artworkId,
    this.artworkType = ArtworkType.AUDIO,
    this.imageFile,
    this.trailing,
    this.tag = ''
  }) : super(key: key);
  
  final int artworkId;
  final ArtworkType artworkType;
  final String title;
  final String subtitle;
  final File? imageFile;
  final Widget? trailing;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12)),                
      leading: ArtworkFileImage(
        artworkId: artworkId,
        artworkType: artworkType,
        imageFile: imageFile,
        tag: tag,
      ),
      trailing: trailing,
    );
  }
}