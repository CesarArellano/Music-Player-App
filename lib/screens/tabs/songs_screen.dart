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
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initSong();
  }

  void _initSong() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        final lastSongId = UserPreferences().lastSongId;
        final musicPlayerCubit = context.read<MusicPlayerCubit>();
        final uiCubit = context.read<UICubit>();

        uiCubit.updateDominantColorCollection(
          UserPreferences().dominantColorCollection,
        );
        musicPlayerCubit
            .updateCurrentPlaylist(musicPlayerCubit.state.songList);
        MusicActions.initStreams(context);

        if (lastSongId == 0) return;

        final foundSong = musicPlayerCubit.state.songList.firstWhere(
          (song) => song.id == lastSongId,
          orElse: () => SongModel({'_id': 0}),
        );

        musicPlayerCubit.updateSongPlayed(foundSong);

        if (foundSong.id == 0) return;
        if (!mounted) return;

        MusicActions.initSongs(
          context,
          foundSong,
          heroId: 'current-song-${foundSong.id}',
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final musicPlayerState = context.watch<MusicPlayerCubit>().state;
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
  }
}
