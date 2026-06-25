import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/helpers.dart';
import '../helpers/music_actions.dart';
import '../share_prefs/user_preferences.dart';
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
    final onAudioQuery = audioPlayerHandler.get<OnAudioQuery>();
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerCubit = context.watch<MusicPlayerCubit>();
    final audioControlCubit = context.watch<AudioControlCubit>();
    final musicPlayerState = musicPlayerCubit.state;
    final audioControlState = audioControlCubit.state;
    final uiCubit = context.read<UICubit>();
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File(
      '${musicPlayerState.appDirectory}/${songPlayed.albumId}.jpg',
    );
    final isFavoriteSong = musicPlayerState.isFavoriteSong(songPlayed.id);

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

                  if (currentIndex ==
                      musicPlayerState.currentPlaylist.length - 1) {
                    return _addToQueue(
                      context: context,
                      audioPlayer: audioPlayer,
                      musicPlayerCubit: musicPlayerCubit,
                      audioControlCubit: audioControlCubit,
                      uiCubit: uiCubit,
                      song: songPlayed,
                    );
                  }

                  final tempList = [...musicPlayerState.currentPlaylist]
                    ..insert(currentIndex + 1, songPlayed);
                  musicPlayerCubit.updateCurrentPlaylist(tempList);
                  MusicActions.openAudios(
                    audioPlayer: audioPlayer,
                    index: currentIndex,
                    seek: audioControlState.currentDuration,
                    audioControlCubit: audioControlCubit,
                    musicPlayerCubit: musicPlayerCubit,
                    uiCubit: uiCubit,
                  );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.library_add_rounded,
                    color: AppTheme.lightTextColor),
                title: const Text('Add to playing queue'),
                onTap: () => _addToQueue(
                  context: context,
                  audioPlayer: audioPlayer,
                  musicPlayerCubit: musicPlayerCubit,
                  audioControlCubit: audioControlCubit,
                  uiCubit: uiCubit,
                  song: songPlayed,
                ),
              ),
              if (musicPlayerState.playLists.isNotEmpty &&
                  Platform.isAndroid) ...[
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
                            items: musicPlayerState.playLists
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
                                      musicPlayerCubit.refreshPlaylist();
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
                  final filesToShare = <XFile>[XFile(songPlayed.data)];
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
                    final albumId = songPlayed.albumId;
                    final artistId = songPlayed.artistId;

                    if (widget.isPlaylist) {
                      onAudioQuery.removeFromPlaylist(
                          widget.playlistId!, songPlayed.id);
                      return await musicPlayerCubit.searchByPlaylistId(
                          widget.playlistId!,
                          force: true);
                    }

                    if (albumId != null) {
                      musicPlayerCubit.searchByAlbumId(albumId);
                      if (musicPlayerState
                                  .albumCollection[albumId]?.length ==
                              1 &&
                          await imageFile.exists()) {
                        MusicActions.deleteFile(imageFile);
                      }
                    }

                    final isDeleted =
                        await MusicActions.deleteFile(File(songPlayed.data));

                    if (!context.mounted) return;
                    Navigator.pop(context);

                    if (isDeleted) {
                      context.read<MusicPlayerCubit>().getAllSongs();

                      if (albumId != null) {
                        musicPlayerCubit.searchByAlbumId(albumId, force: true);
                      }
                      if (artistId != null) {
                        musicPlayerCubit.searchByArtistId(artistId,
                            force: true);
                      }

                      Helpers.showSnackbar(message: 'Successfully removed');
                      return;
                    }

                    Helpers.showSnackbar(
                      message: 'Error when deleting',
                      backgroundColor: Colors.red,
                    );
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
                      final favoriteList = [...musicPlayerState.favoriteList];
                      final favoriteSongList = [
                        ...musicPlayerState.favoriteSongList
                      ];

                      if (isFavoriteSong) {
                        favoriteList
                            .removeWhere((s) => s.id == songPlayed.id);
                        favoriteSongList.removeWhere(
                            (id) => id == songPlayed.id.toString());
                      } else {
                        final index = musicPlayerState.songList
                            .indexWhere((s) => s.id == songPlayed.id);
                        favoriteList
                            .add(musicPlayerState.songList[index]);
                        favoriteSongList.add(songPlayed.id.toString());
                      }

                      musicPlayerCubit.updateFavorites(
                        favoriteList: favoriteList,
                        favoriteSongList: favoriteSongList,
                      );
                      UserPreferences().favoriteSongList = favoriteSongList;
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
    required AudioPlayer audioPlayer,
    required MusicPlayerCubit musicPlayerCubit,
    required AudioControlCubit audioControlCubit,
    required UICubit uiCubit,
  }) {
    musicPlayerCubit.updateCurrentPlaylist([
      ...musicPlayerCubit.state.currentPlaylist,
      song,
    ]);
    MusicActions.openAudios(
      audioPlayer: audioPlayer,
      audioControlCubit: audioControlCubit,
      musicPlayerCubit: musicPlayerCubit,
      uiCubit: uiCubit,
      index: audioControlCubit.state.currentIndex,
      seek: audioControlCubit.state.currentDuration,
    );
    Navigator.pop(context);
  }
}
