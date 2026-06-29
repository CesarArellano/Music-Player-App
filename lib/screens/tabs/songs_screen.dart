import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../../cubits/cubits.dart';
import '../../extensions/extensions.dart';
import '../../helpers/music_actions.dart';
import '../../share_prefs/user_preferences.dart';
import '../../widgets/widgets.dart';

// Each grid row has this aspect ratio; used to compute the scroll offset for
// the alphabet fast-scroll without measuring individual tiles.
const double _kSongTileAspectRatio = 5.5;

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _initialized = false;

  final ScrollController _scrollController = ScrollController();

  // Memoized alphabet index, recomputed only when the song list changes.
  List<SongModel>? _indexedFor;
  List<String> _letters = const [];
  Map<String, int> _letterToIndex = const {};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Builds (and caches) the letter rail and the first-index per letter.
  void _buildIndex(List<SongModel> songList) {
    if (identical(_indexedFor, songList)) return;
    _indexedFor = songList;

    final letters = <String>[];
    final letterToIndex = <String, int>{};
    for (int i = 0; i < songList.length; i++) {
      final letter = _firstLetter(songList[i].title.value());
      if (!letterToIndex.containsKey(letter)) {
        letterToIndex[letter] = i;
        letters.add(letter);
      }
    }
    _letters = letters;
    _letterToIndex = letterToIndex;
  }

  String _firstLetter(String title) {
    final trimmed = title.trimLeft();
    if (trimmed.isEmpty) return '#';
    final first = (_accents[trimmed[0]] ?? trimmed[0]).toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  // Fold common Latin accents to their base letter so accented titles index
  // under the expected letter (e.g. "Ángel" → A).
  static const Map<String, String> _accents = {
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
    'Á': 'A', 'À': 'A', 'Ä': 'A', 'Â': 'A', 'Ã': 'A', 'Å': 'A',
    'É': 'E', 'È': 'E', 'Ë': 'E', 'Ê': 'E',
    'Í': 'I', 'Ì': 'I', 'Ï': 'I', 'Î': 'I',
    'Ó': 'O', 'Ò': 'O', 'Ö': 'O', 'Ô': 'O', 'Õ': 'O',
    'Ú': 'U', 'Ù': 'U', 'Ü': 'U', 'Û': 'U',
    'Ñ': 'N', 'Ç': 'C',
  };

  void _jumpToLetter(String letter, int crossAxisCount, double viewportWidth) {
    final index = _letterToIndex[letter];
    if (index == null || !_scrollController.hasClients) return;

    final rowExtent =
        (viewportWidth / crossAxisCount) / _kSongTileAspectRatio;
    final offset = (index ~/ crossAxisCount) * rowExtent;
    final max = _scrollController.position.maxScrollExtent;
    _scrollController.jumpTo(offset.clamp(0.0, max));
  }

  @override
  void initState() {
    super.initState();
    // Handle the case where songs are already loaded before the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      final state = context.read<LibraryCubit>().state;
      if (!state.isLoading) {
        _initialized = true;
        _initSong(context, state);
      }
    });
  }

  void _initSong(BuildContext context, LibraryState state) {
    final lastSongId = UserPreferences().lastSongId;
    final playbackCubit = context.read<PlaybackStateCubit>();
    final uiCubit = context.read<UICubit>();

    uiCubit.updateDominantColorCollection(
      UserPreferences().dominantColorCollection,
    );
    playbackCubit.updateCurrentPlaylist(state.songList);

    if (lastSongId == 0) return;

    final foundSong = state.songList.firstWhere(
      (song) => song.id == lastSongId,
      orElse: () => SongModel({'_id': 0}),
    );

    playbackCubit.updateSongPlayed(foundSong);

    if (foundSong.id == 0) return;
    MusicActions.initSongs(context, foundSong, heroId: 'current-song-${foundSong.id}');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocListener<LibraryCubit, LibraryState>(
      // Fires once when the loading completes (handles the still-loading case).
      listenWhen: (prev, curr) => prev.isLoading && !curr.isLoading,
      listener: (context, state) {
        if (_initialized) return;
        _initialized = true;
        _initSong(context, state);
      },
      child: Builder(
        builder: (context) {
          final musicPlayerState = context.watch<LibraryCubit>().state;
          final songList = musicPlayerState.songList;

          if (musicPlayerState.isLoading) {
            return CustomLoader(
                isCreatingArtworks: musicPlayerState.isCreatingArtworks);
          }

          if (songList.isEmpty) {
            return const Center(
              child: Text(
                'No Songs',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            );
          }

          _buildIndex(songList);

          return OrientationBuilder(
            builder: (context, orientation) {
              final crossAxisCount =
                  orientation == Orientation.landscape ? 2 : 1;

              return Stack(
                children: [
                  GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: _kSongTileAspectRatio,
                    ),
                    itemCount: songList.length,
                    itemBuilder: (_, int i) {
                      final song = songList[i];
                      final imageFile = File(
                        '${musicPlayerState.appDirectory}/${song.albumId}.jpg',
                      );
                      final heroId = 'songs-${song.id}';

                      return RippleTile(
                        child: CustomListTile(
                          title: song.title.value(),
                          subtitle: song.artist.valueEmpty('No Artist'),
                          artworkId: song.id,
                          imageFile: imageFile,
                          tag: heroId,
                        ),
                        onTap: () => MusicActions.songPlayAndPause(
                          context,
                          song,
                          PlaylistType.songs,
                          heroId: heroId,
                        ),
                        onLongPress: () => showModalBottomSheet(
                          context: context,
                          builder: (_) => MoreSongOptionsModal(song: song),
                        ),
                      );
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: AlphabetScrollbar(
                        letters: _letters,
                        controller: _scrollController,
                        onLetterSelected: (letter) => _jumpToLetter(
                          letter,
                          crossAxisCount,
                          MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

