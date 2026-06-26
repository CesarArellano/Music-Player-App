import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../cubits/cubits.dart';
import '../../extensions/extensions.dart';
import '../../helpers/music_actions.dart';
import '../../share_prefs/user_preferences.dart';
import '../../widgets/widgets.dart';

class SongsScreen extends StatefulWidget {
  const SongsScreen({super.key});

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen>
    with AutomaticKeepAliveClientMixin {
  bool _initialized = false;

  @override
  bool get wantKeepAlive => true;

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

          return musicPlayerState.isLoading
              ? CustomLoader(isCreatingArtworks: musicPlayerState.isCreatingArtworks)
              : songList.isNotEmpty
                  ? OrientationBuilder(
                      builder: (context, orientation) => GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              orientation == Orientation.landscape ? 2 : 1,
                          childAspectRatio: 5.5,
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
                    )
                  : const Center(
                      child: Text(
                        'No Songs',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    );
        },
      ),
    );
  }
}
