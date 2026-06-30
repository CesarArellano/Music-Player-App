import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focus_music_player/cubits/cubits.dart';
import 'package:focus_music_player/widgets/artwork_file_image.dart';
import 'package:music_query_selector/music_query_selector.dart' show ArtworkType;

import '../theme/app_theme.dart';

class CustomListTile extends StatelessWidget {
  
  const CustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.artworkId,
    this.artworkType = ArtworkType.AUDIO,
    this.imageFile,
    this.trailing,
    this.tag = ''
  });
  
  final int artworkId;
  final ArtworkType artworkType;
  final String title;
  final String subtitle;
  final File? imageFile;
  final Widget? trailing;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final isActive = context.select((PlaybackStateCubit cubit) => cubit.state.songPlayed.id == artworkId);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: isActive ? AppTheme.accentColor : AppTheme.white,
          fontWeight: FontWeight.w400,
          fontSize: 15
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
      ),
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