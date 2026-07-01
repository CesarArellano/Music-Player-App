import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart' show SongModel;

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../theme/app_theme.dart';
import 'artwork_file_image.dart';

class SongDetailsDialog extends StatelessWidget {
  const SongDetailsDialog({super.key, required this.song});

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final appDirectory = context.read<LibraryCubit>().state.appDirectory;
    final imageFile = File('$appDirectory/${song.albumId}.jpg');
    final duration = Duration(milliseconds: song.duration ?? 0);

    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: const Text('Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ArtworkFileImage(
                    artworkId: song.id,
                    imageFile: imageFile,
                    height: 170,
                    width: 170,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow('Title', song.title.value()),
              _DetailRow('File name', song.displayName),
              _DetailRow('File path', song.data ?? '-'),
              _DetailRow('Format', song.audioFormatName),
              _DetailRow('Track number', '${song.track ?? '-'}'),
              _DetailRow('Size', '${(song.size / 1048576).round()} MB'),
              _DetailRow('Length', duration.timeString),
              _DetailRow('Album', song.album ?? '-'),
              _DetailRow('Artist', song.artist.valueEmpty('-')),
              if (song.composer?.isNotEmpty == true)
                _DetailRow('Composer', song.composer!),
              if (song.genre?.isNotEmpty == true)
                _DetailRow('Genre', song.genre!),
              if (song.dateAdded != null)
                _DetailRow('Date added', song.dateAdded!.toTimestampString()),
              if (song.dateModified != null)
                _DetailRow('Date modified', song.dateModified!.toTimestampString()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Edit', style: TextStyle(color: AppTheme.lightTextColor)),
        ),
        Expanded(
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
