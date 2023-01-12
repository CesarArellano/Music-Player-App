import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/artwork_file_image.dart';
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
  }) : super(key: key);
  
  final int artworkId;
  final ArtworkType artworkType;
  final String title;
  final String subtitle;
  final File? imageFile;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12)),                
      leading: ArtworkFileImage(
        artworkId: artworkId,
        artworkType: artworkType,
        imageFile: imageFile
      ),
      trailing: trailing,
    );
  }
}