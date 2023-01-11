import 'dart:io';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show ArtworkType;
import 'package:music_player_app/widgets/widgets.dart';

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
      leading: (imageFile ?? File('')).existsSync() 
        ? ClipRRect(
          borderRadius: BorderRadius.circular(2.5),
          child: Image.file(
            imageFile!,
            width: 55,
            height: 55,
            filterQuality: FilterQuality.low,
            gaplessPlayback: true,
          ),
        )
        : ArtworkImage(
          artworkId: artworkId,
          type: artworkType,
          width: 55,
          height: 55,
          size: 250,
          radius: BorderRadius.circular(2.5),
        ),
        trailing: trailing,
    );
  }
}