import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart' show SongModel, ArtworkType;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import 'album_selected_screen.dart';
import 'artist_selected_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Full-screen search built to match the reference: a rounded pill field with
/// an inline search icon and mic, plus an external "Cancel". The scaffold is
/// transparent so the global AppBackground shows through, like the home screen.
class MusicSearchScreen extends StatefulWidget {
  const MusicSearchScreen({super.key});

  @override
  State<MusicSearchScreen> createState() => _MusicSearchScreenState();
}

class _MusicSearchScreenState extends State<MusicSearchScreen> {
  final String localeId = 'es-MX';
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  String _query = '';
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() {
      if (_controller.text != _query) {
        setState(() => _query = _controller.text);
      }
    });
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _toggleListening() async {
    if (!_speechEnabled) return;
    if (_speech.isNotListening) {
      FocusScope.of(context).unfocus();
      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: SpeechListenOptions(
          localeId: localeId,
        ),
      );
    } else {
      await _speech.stop();
    }
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    _controller.value = _controller.value.copyWith(
      text: result.recognizedWords,
      selection: TextSelection.collapsed(offset: result.recognizedWords.length),
    );
  }

  @override
  void dispose() {
    _speech.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            _SearchField(
              controller: _controller,
              hasText: _query.isNotEmpty,
              isListening: _speech.isListening,
              onClear: _controller.clear,
              onCancel: () => Navigator.pop(context),
              onMicTap: _toggleListening,
            ),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_query.isEmpty) return _emptyContainer();

    final libraryState = context.watch<LibraryCubit>().state;
    final result = libraryState.searchByQuery(_query);
    final songs = result.songs;
    final albums = result.albums;
    final artists = result.artists;

    if (songs.isEmpty && albums.isEmpty && artists.isEmpty) {
      return _emptyContainer();
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        if (songs.isNotEmpty) _SectionTitle(title: 'Songs', length: songs.length),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) => _songItem(context, songs[i], libraryState),
            childCount: songs.length,
          ),
        ),
        if (artists.isNotEmpty)
          _SectionTitle(title: 'Artists', length: artists.length),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final artist = artists[i];
              return RippleTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ArtistSelectedScreen(artistSelected: artist),
                  ),
                ),
                child: CustomListTile(
                  artworkId: artist.id,
                  artworkType: ArtworkType.ARTIST,
                  title: artist.artist,
                  subtitle:
                      '${artist.numberOfAlbums} ${artist.numberOfAlbums.nonNullValue() > 1 ? 'Albums' : 'Album'} • ${artist.numberOfTracks} Songs',
                ),
              );
            },
            childCount: artists.length,
          ),
        ),
        if (albums.isNotEmpty)
          _SectionTitle(title: 'Albums', length: albums.length),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              final album = albums[i];
              return RippleTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AlbumSelectedScreen(albumSelected: album),
                  ),
                ),
                child: CustomListTile(
                  artworkId: album.id,
                  imageFile: File(
                    '${libraryState.appDirectory}/${album.id}.jpg',
                  ),
                  title: album.album,
                  subtitle:
                      '${album.numOfSongs} ${album.numOfSongs > 1 ? 'songs' : 'song'}',
                ),
              );
            },
            childCount: albums.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _emptyContainer() {
    return Center(
      child: Icon(
        Icons.music_note,
        size: 130,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _songItem(
    BuildContext context,
    SongModel song,
    LibraryState libraryState,
  ) {
    final imageFile = File(
      '${libraryState.appDirectory}/${song.albumId}.jpg',
    );
    final heroId = 'search-song-${song.id}';

    return RippleTile(
      child: CustomListTile(
        imageFile: imageFile,
        title: song.title.value(),
        subtitle: song.artist.valueEmpty('No Artist'),
        artworkId: song.id,
        tag: heroId,
      ),
      onTap: () =>
          MusicActions.songPlayAndPause(context, song, PlaylistType.songs, heroId: heroId),
      onLongPress: () => showModalBottomSheet(
        context: context,
        builder: (_) => MoreSongOptionsModal(song: song),
      ),
    );
  }
}

/// The pill-shaped query field with an inline search icon + mic, and a trailing
/// "Cancel" action outside the pill.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.isListening,
    required this.onClear,
    required this.onCancel,
    required this.onMicTap,
  });

  final TextEditingController controller;
  final bool hasText;
  final bool isListening;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    const hintColor = Colors.white60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: isListening ? 'Listening...' : 'Search',
                  hintStyle: const TextStyle(color: hintColor, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: const Icon(Icons.search, color: hintColor),
                  suffixIcon: hasText
                      ? IconButton(
                          icon: const Icon(Icons.close, color: hintColor),
                          splashRadius: 20,
                          onPressed: onClear,
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.mic,
                            color: isListening ? Colors.redAccent : hintColor,
                          ),
                          splashRadius: 20,
                          onPressed: onMicTap,
                        ),
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              'Cancel',
              style: TextStyle(color: hintColor, fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.length});

  final String title;
  final int length;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 18),
                children: [
                  TextSpan(
                    text: title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(
                    text: ' ($length)',
                    style: const TextStyle(color: AppTheme.lightTextColor),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.lightTextColor),
          ],
        ),
      ),
    );
  }
}
