import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:music_query_selector/music_query_selector.dart' show SongModel;
import 'package:permission_handler/permission_handler.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../services/snackbar_service.dart';
import '../services/tag_editor_service.dart';
import '../theme/app_theme.dart';
import 'artwork_file_image.dart';

class TagEditorDialog extends StatefulWidget {
  const TagEditorDialog({super.key, required this.song});

  final SongModel song;

  @override
  State<TagEditorDialog> createState() => _TagEditorDialogState();
}

class _TagEditorDialogState extends State<TagEditorDialog> {
  bool _isLoading = true;
  bool _isSaving = false;

  late final TextEditingController _titleController;
  late final TextEditingController _albumController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumArtistController;
  late final TextEditingController _composerController;
  late final TextEditingController _genreController;
  late final TextEditingController _yearController;
  late final TextEditingController _trackController;

  Uint8List? _artworkBytes;
  bool _artworkChanged = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _albumController = TextEditingController();
    _artistController = TextEditingController();
    _albumArtistController = TextEditingController();
    _composerController = TextEditingController();
    _genreController = TextEditingController();
    _yearController = TextEditingController();
    _trackController = TextEditingController();
    _loadTags();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _albumController.dispose();
    _artistController.dispose();
    _albumArtistController.dispose();
    _composerController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackController.dispose();
    super.dispose();
  }

  Future<void> _loadTags() async {
    final filePath = widget.song.data;
    if (filePath == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await audioPlayerHandler<TagEditorService>().readTags(filePath);
      if (!mounted) return;
      _titleController.text = data.title;
      _albumController.text = data.album;
      _artistController.text = data.artist;
      _albumArtistController.text = data.albumArtist;
      _composerController.text = data.composer;
      _genreController.text = data.genre;
      _yearController.text = data.year;
      _trackController.text = data.track;
      setState(() {
        _artworkBytes = data.artworkBytes;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickArtwork() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _artworkBytes = bytes;
      _artworkChanged = true;
    });
  }

  Future<void> _onSave() async {
    final filePath = widget.song.data;
    if (filePath == null) return;
    setState(() => _isSaving = true);
    try {
      final data = TagData(
        title: _titleController.text.trim(),
        album: _albumController.text.trim(),
        artist: _artistController.text.trim(),
        albumArtist: _albumArtistController.text.trim(),
        composer: _composerController.text.trim(),
        genre: _genreController.text.trim(),
        year: _yearController.text.trim(),
        track: _trackController.text.trim(),
        artworkBytes: _artworkChanged ? _artworkBytes : null,
      );
      await audioPlayerHandler<TagEditorService>().writeTags(filePath, data);
      if (_artworkChanged && _artworkBytes != null && mounted) {
        final appDirectory = context.read<LibraryCubit>().state.appDirectory;
        await File('$appDirectory/${widget.song.albumId}.jpg').writeAsBytes(_artworkBytes!);
      }
      if (!mounted) return;
      context.read<LibraryCubit>().getAllSongs();
      Navigator.pop(context);
      SnackbarService.instance.showSnackbar(message: 'Tags saved');
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (e.code == 'PERMISSION_DENIED') {
        final status = await Permission.manageExternalStorage.request();
        if (status.isGranted && mounted) _onSave();
      } else {
        SnackbarService.instance.showSnackbar(
          message: 'Error: ${e.message ?? 'Could not save tags'}',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(
      '${context.read<LibraryCubit>().state.appDirectory}/${widget.song.albumId}.jpg',
    );

    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: const Text(
        'Tag Editor',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _artworkBytes != null
                                ? Image.memory(
                                    _artworkBytes!,
                                    height: 150,
                                    width: 150,
                                    fit: BoxFit.cover,
                                  )
                                : ArtworkFileImage(
                                    artworkId: widget.song.id,
                                    imageFile: imageFile,
                                    height: 150,
                                    width: 150,
                                  ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: GestureDetector(
                              onTap: _pickArtwork,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TagField(label: 'Title', controller: _titleController),
                    _TagField(label: 'Album', controller: _albumController),
                    _TagField(label: 'Artist', controller: _artistController),
                    _TagField(label: 'Album Artist', controller: _albumArtistController),
                    _TagField(label: 'Composer', controller: _composerController),
                    _TagField(label: 'Genre', controller: _genreController),
                    _TagField(
                      label: 'Year',
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                    ),
                    _TagField(
                      label: 'Track',
                      controller: _trackController,
                      keyboardType: TextInputType.number,
                    ),
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
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.lightTextColor)),
            ),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isSaving ? null : _onSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TagField extends StatelessWidget {
  const _TagField({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppTheme.lightTextColor, fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.lightTextColor),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppTheme.primaryColor),
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}
