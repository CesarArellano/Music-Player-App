import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart' show SongModel;

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../theme/app_theme.dart';
import 'artwork_file_image.dart';
import 'tag_editor_dialog.dart';

class SongDetailsDialog extends StatefulWidget {
  const SongDetailsDialog({super.key, required this.song});

  final SongModel song;

  @override
  State<SongDetailsDialog> createState() => _SongDetailsDialogState();
}

class _SongDetailsDialogState extends State<SongDetailsDialog> {
  void _onEditTap() {
    showDialog(
      context: context,
      builder: (_) => TagEditorDialog(song: widget.song),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appDirectory = context.read<LibraryCubit>().state.appDirectory;
    final imageFile = File('$appDirectory/${widget.song.albumId}.jpg');
    final duration = Duration(milliseconds: widget.song.duration ?? 0);

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
                    artworkId: widget.song.id,
                    imageFile: imageFile,
                    height: 170,
                    width: 170,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _DetailRow('Title', widget.song.title.value()),
              _DetailRow('File name', widget.song.displayName),
              _DetailRow('File path', widget.song.data ?? '-'),
              _DetailRow('Format', widget.song.audioFormatName),
              _DetailRow('Track number', '${widget.song.track ?? '-'}'),
              _DetailRow('Size', '${(widget.song.size / 1048576).round()} MB'),
              _DetailRow('Length', duration.timeString),
              _DetailRow('Album', widget.song.album ?? '-'),
              _DetailRow('Artist', widget.song.artist.valueEmpty('-')),
              if (widget.song.composer?.isNotEmpty == true)
                _DetailRow('Composer', widget.song.composer!),
              if (widget.song.genre?.isNotEmpty == true)
                _DetailRow('Genre', widget.song.genre!),
              if (widget.song.dateAdded != null)
                _DetailRow('Date added', widget.song.dateAdded!.toTimestampString()),
              if (widget.song.dateModified != null)
                _DetailRow('Date modified', widget.song.dateModified!.toTimestampString()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: _onEditTap,
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
