import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel;

import '../extensions/extensions.dart';
import '../theme/app_theme.dart';

class SongDetailsDialog extends StatelessWidget {
  const SongDetailsDialog({
    super.key,
    required this.song,
  });

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: song.duration ?? 0);
    
    return AlertDialog(
      backgroundColor: AppTheme.primaryColor,
      title: const Text('Details'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          _RowLabel(label: 'Title: ', value: song.title.value()),
          const SizedBox(height: 15),
          _RowLabel(label: 'Album: ', value: '${ song.album }'),
          const SizedBox(height: 15),
          _RowLabel(label: 'File name: ', value: song.displayName),
          const SizedBox(height: 15),
          _RowLabel(label: 'File path: ', value: song.data),
          const SizedBox(height: 15),
          _RowLabel(label: 'Size: ', value: '${ (song.size / 1048576).round() } MB'),
          const SizedBox(height: 15),
          _RowLabel(label: 'Format: ', value: song.fileExtension),
          const SizedBox(height: 15),
          _RowLabel(label: 'Length: ', value: duration.getTimeString()),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      actions: <Widget> [
        TextButton(
          child: const Text('OK'),
          onPressed:() {
            Navigator.pop(context, false);
          } , 
        ),
      ],
    );
  }
}

class _RowLabel extends StatelessWidget {
  const _RowLabel({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 16, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: label),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.w400)),
        ]
      ),
    );
  }
}