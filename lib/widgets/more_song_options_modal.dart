import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../services/favorites_service.dart';
import '../services/playback_service.dart';
import '../services/snackbar_service.dart';
import '../theme/app_theme.dart';
import 'custom_list_tile.dart';
import 'song_details_dialog.dart';

class MoreSongOptionsModal extends StatefulWidget {
  const MoreSongOptionsModal({
    super.key,
    required this.song,
    this.isPlaylist = false,
    this.disabledDeleteButton = false,
    this.playlistId,
  });

  final SongModel song;
  final int? playlistId;
  final bool isPlaylist;
  final bool disabledDeleteButton;

  @override
  State<MoreSongOptionsModal> createState() => _MoreSongOptionsModalState();
}

class _MoreSongOptionsModalState extends State<MoreSongOptionsModal> {
  int? _selectedPlaylistId;

  @override
  Widget build(BuildContext context) {
    final songPlayed = widget.song;
    final onAudioQuery = audioPlayerHandler.get<MusicQuerySelector>();
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final favoritesState = context.watch<FavoritesCubit>().state;
    final libraryState = context.watch<LibraryCubit>().state;
    final audioControlCubit = context.watch<AudioControlCubit>();
    final audioControlState = audioControlCubit.state;
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File(
      '${libraryState.appDirectory}/${songPlayed.albumId}.jpg',
    );
    final isFavoriteSong = favoritesState.isFavoriteSong(songPlayed.id);

    return OrientationBuilder(
      builder: (_, orientation) => Stack(
        children: [
          ListView(
            shrinkWrap: true,
            physics: orientation == Orientation.portrait
                ? const NeverScrollableScrollPhysics()
                : const ScrollPhysics(),
            children: [
              const SizedBox(height: 70),
              ListTile(
                leading: const Icon(Icons.replay_outlined,
                    color: AppTheme.lightTextColor),
                title: const Text('Play next'),
                onTap: () {
                  final currentIndex = audioControlState.currentIndex;

                  if (currentIndex == playbackState.currentPlaylist.length - 1) {
                    return _addToQueue(
                      context: context,
                      audioControlCubit: audioControlCubit,
                      song: songPlayed,
                    );
                  }

                  final tempList = [...playbackState.currentPlaylist]
                    ..insert(currentIndex + 1, songPlayed);
                  context.read<PlaybackStateCubit>().updateCurrentPlaylist(tempList);
                  final playbackService = audioPlayerHandler<PlaybackService>();
                  playbackService.loadPlaylist(
                    songs: tempList,
                    initialIndex: currentIndex,
                    appDirectory: libraryState.appDirectory,
                    initialPosition: audioControlState.currentDuration,
                  );
                  playbackService.play();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_add_rounded,
                    color: AppTheme.lightTextColor),
                title: const Text('Add to playing queue'),
                onTap: () => _addToQueue(
                  context: context,
                  audioControlCubit: audioControlCubit,
                  song: songPlayed,
                ),
              ),
              if (libraryState.playLists.isNotEmpty && Platform.isAndroid) ...[
                ListTile(
                  leading: const Icon(Icons.playlist_add,
                      color: AppTheme.lightTextColor),
                  title: const Text('Add to Playlist'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (_, setInnerState) => AlertDialog(
                          backgroundColor: AppTheme.primaryColor,
                          title: const Text('Add to playlist'),
                          content: DropdownButton<int?>(
                            isExpanded: true,
                            value: _selectedPlaylistId,
                            dropdownColor: AppTheme.primaryColor,
                            hint: const Text('Select a playlist',
                                style: TextStyle(color: Colors.white)),
                            items: libraryState.playLists
                                .map((e) => DropdownMenuItem<int?>(
                                      value: e.id,
                                      child: Text(e.playlist,
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ))
                                .toList(),
                            onChanged: (int? value) =>
                                setInnerState(() => _selectedPlaylistId = value),
                          ),
                          actions: [
                            TextButton(
                              onPressed: _selectedPlaylistId == null
                                  ? null
                                  : () {
                                      onAudioQuery.addToPlaylist(
                                          _selectedPlaylistId!,
                                          widget.song.id);
                                      context.read<LibraryCubit>().refreshPlaylist();
                                      Navigator.pop(context);
                                    },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Divider(color: AppTheme.lightTextColor, height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.share,
                    color: AppTheme.lightTextColor),
                title: const Text('Share Audio'),
                onTap: () async {
                  if (songPlayed.data == null) return;
                  final filesToShare = <XFile>[XFile(songPlayed.data!)];
                  if (await imageFile.exists()) {
                    filesToShare.add(XFile(imageFile.path));
                  }
                  await SharePlus.instance.share(ShareParams(
                    files: filesToShare,
                    text:
                        'I share you the song ${widget.song.title.value()}',
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline,
                    color: AppTheme.lightTextColor),
                title: const Text('Details'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => SongDetailsDialog(song: widget.song),
                ),
              ),
              if (!widget.disabledDeleteButton)
                ListTile(
                  leading: Icon(
                    widget.isPlaylist
                        ? Icons.playlist_remove
                        : Icons.delete_forever,
                    color: AppTheme.lightTextColor,
                  ),
                  title: Text(
                    widget.isPlaylist
                        ? 'Remove from this playlist'
                        : 'Delete from device',
                  ),
                  onTap: () async {
                    final libraryCubit = context.read<LibraryCubit>();
                    final playbackService =
                        audioPlayerHandler<PlaybackService>();
                    final albumId = songPlayed.albumId;
                    final artistId = songPlayed.artistId;

                    if (widget.isPlaylist) {
                      onAudioQuery.removeFromPlaylist(
                          widget.playlistId!, songPlayed.id);
                      return await libraryCubit.searchByPlaylistId(
                          widget.playlistId!,
                          force: true);
                    }

                    // Native MediaStore delete (system confirmation dialog) on
                    // Android; legacy file delete elsewhere.
                    final isDeleted = Platform.isAndroid
                        ? await onAudioQuery.deleteSongs([songPlayed.id])
                        : (songPlayed.data != null &&
                            await MusicActions.deleteFile(
                                File(songPlayed.data!)));

                    if (!isDeleted) {
                      SnackbarService.instance.showSnackbar(
                        message: 'Error when deleting',
                        backgroundColor: Colors.red,
                      );
                      return;
                    }

                    // Drop it from the live queue (advances to the next track)
                    // and clean up the cached art if it was the album's last song.
                    await playbackService.removeFromQueue(songPlayed);
                    if (albumId != null &&
                        libraryState.albumCollection[albumId]?.length == 1 &&
                        await imageFile.exists()) {
                      // App-owned cache file; delete directly (no permission).
                      imageFile.delete();
                    }

                    libraryCubit.getAllSongs();
                    if (albumId != null) {
                      libraryCubit.searchByAlbumId(albumId, force: true);
                    }
                    if (artistId != null) {
                      libraryCubit.searchByArtistId(artistId, force: true);
                    }

                    if (context.mounted) Navigator.pop(context);
                    SnackbarService.instance
                        .showSnackbar(message: 'Successfully removed');
                  },
                ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomListTile(
                  artworkId: songPlayed.id,
                  title: songPlayed.title.value(),
                  subtitle:
                      '${songPlayed.artist.valueEmpty('No Artist')} • ${duration.getTimeString()}',
                  imageFile: imageFile,
                  trailing: IconButton(
                    onPressed: () {
                      audioPlayerHandler<FavoritesService>().toggle(
                        songPlayed,
                        favoritesState: favoritesState,
                        allSongs: libraryState.songList,
                      );
                    },
                    icon: Icon(
                      isFavoriteSong
                          ? Icons.favorite
                          : Icons.favorite_border,
                    ),
                  ),
                ),
                const Divider(color: AppTheme.lightTextColor, height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToQueue({
    required BuildContext context,
    required SongModel song,
    required AudioControlCubit audioControlCubit,
  }) {
    final playbackCubit = context.read<PlaybackStateCubit>();
    final updatedPlaylist = [
      ...playbackCubit.state.currentPlaylist,
      song,
    ];
    playbackCubit.updateCurrentPlaylist(updatedPlaylist);
    final playbackService = audioPlayerHandler<PlaybackService>();
    playbackService.loadPlaylist(
      songs: updatedPlaylist,
      initialIndex: audioControlCubit.state.currentIndex,
      appDirectory: context.read<LibraryCubit>().state.appDirectory,
      initialPosition: audioControlCubit.state.currentDuration,
    );
    playbackService.play();
    Navigator.pop(context);
  }
}
