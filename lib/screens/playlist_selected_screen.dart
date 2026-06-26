import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_icon_text_button.dart';
import '../widgets/widgets.dart';

class PlaylistSelectedScreen extends StatefulWidget {
  const PlaylistSelectedScreen({super.key, required this.playlist});

  final PlaylistModel playlist;

  @override
  State<PlaylistSelectedScreen> createState() =>
      _PlaylistSelectedScreenState();
}

class _PlaylistSelectedScreenState extends State<PlaylistSelectedScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getSongs();
  }

  void _getSongs() {
    final cubit = context.read<LibraryCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await cubit.searchByPlaylistId(
        widget.playlist.id,
        force: (cubit.state.playlistCollection[widget.playlist.id]?.length ??
                0) !=
            widget.playlist.numOfSongs,
      );
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final songPlayed = context.watch<PlaybackStateCubit>().state.songPlayed;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.playlist.playlist),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : libraryState.playlistCollection[widget.playlist.id]!.isEmpty
              ? _EmptyList(playlist: widget.playlist)
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (libraryState
                              .playlistCollection[widget.playlist.id] ??
                          [])
                      .length,
                  itemBuilder: (_, int i) {
                    final song = libraryState
                        .playlistCollection[widget.playlist.id]![i];
                    final imageFile = File(
                      '${libraryState.appDirectory}/${song.albumId}.jpg',
                    );
                    final heroId = 'playlist-song-${song.id}';

                    return RippleTile(
                      child: CustomListTile(
                        artworkId: song.id,
                        title: song.title.value(),
                        subtitle: song.artist.valueEmpty('No Artist'),
                        imageFile: imageFile,
                        tag: heroId,
                      ),
                      onTap: () => MusicActions.songPlayAndPause(
                        context,
                        song,
                        PlaylistType.playlist,
                        id: widget.playlist.id,
                        heroId: heroId,
                      ),
                      onLongPress: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => MoreSongOptionsModal(
                          song: song,
                          isPlaylist: true,
                          playlistId: widget.playlist.id,
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: (libraryState.isLoading || songPlayed.id == 0)
          ? null
          : const CurrentSongTile(),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.playlist});

  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            maxRadius: 50,
            child: Icon(Icons.music_note_rounded,
                color: Colors.white54, size: 50),
          ),
          const SizedBox(height: 15),
          const Text(
            'No songs',
            style: TextStyle(
                color: AppTheme.lightTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: 140,
            height: 50,
            child: CustomIconTextButton(
              label: 'Add songs',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
