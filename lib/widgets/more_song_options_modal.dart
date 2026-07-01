import 'dart:io' show Platform, File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../screens/album_selected_screen.dart';
import '../screens/artist_selected_screen.dart';
import '../services/favorites_service.dart';
import '../services/file_management_service.dart';
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

  void _goToAlbum() {
    final libraryState = context.read<LibraryCubit>().state;
    final album = libraryState.albumList.firstWhere(
      (a) => a.id == widget.song.albumId,
      orElse: () => AlbumModel({'_id': 0}),
    );
    if (album.id == 0) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => AlbumSelectedScreen(albumSelected: album)),
    );
  }

  void _goToArtist() {
    final libraryState = context.read<LibraryCubit>().state;
    final artist = libraryState.artistList.firstWhere(
      (a) => a.id == widget.song.artistId,
      orElse: () => ArtistModel({'_id': 0}),
    );
    if (artist.id == 0) return;
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => ArtistSelectedScreen(artistSelected: artist)),
    );
  }

  Future<void> _findOnYoutube() async {
    final query = Uri.encodeQueryComponent(
      '${widget.song.title.value()} ${widget.song.artist.valueEmpty('')}',
    );
    final url = Uri.parse('https://www.youtube.com/results?search_query=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _shareAudio() async {
    final song = widget.song;
    if (song.data == null) return;
    final appDirectory = context.read<LibraryCubit>().state.appDirectory;
    final imageFile = File('$appDirectory/${song.albumId}.jpg');
    final filesToShare = <XFile>[XFile(song.data!)];
    if (await imageFile.exists()) filesToShare.add(XFile(imageFile.path));
    await SharePlus.instance.share(ShareParams(
      files: filesToShare,
      text: 'Check out ${song.title.value()}',
    ));
  }

  void _playNext() {
    final audioControlCubit = context.read<AudioControlCubit>();
    final playbackStateCubit = context.read<PlaybackStateCubit>();
    final libraryState = context.read<LibraryCubit>().state;
    final currentIndex = audioControlCubit.state.currentIndex;

    if (currentIndex == playbackStateCubit.state.currentPlaylist.length - 1) {
      return _addToQueue(context: context, audioControlCubit: audioControlCubit, song: widget.song);
    }

    final tempList = [...playbackStateCubit.state.currentPlaylist]
      ..insert(currentIndex + 1, widget.song);
    playbackStateCubit.updateCurrentPlaylist(tempList);
    final playbackService = audioPlayerHandler<PlaybackService>();
    playbackService.loadPlaylist(
      songs: tempList,
      initialIndex: currentIndex,
      appDirectory: libraryState.appDirectory,
      initialPosition: audioControlCubit.state.currentDuration,
    );
    playbackService.play();
    Navigator.pop(context);
  }

  Future<void> _deleteSong() async {
    final onAudioQuery = audioPlayerHandler.get<MusicQuerySelector>();
    final libraryCubit = context.read<LibraryCubit>();
    final libraryState = libraryCubit.state;
    final playbackService = audioPlayerHandler<PlaybackService>();
    final song = widget.song;
    final albumId = song.albumId;
    final artistId = song.artistId;
    final imageFile = File('${libraryState.appDirectory}/${song.albumId}.jpg');

    if (widget.isPlaylist) {
      onAudioQuery.removeFromPlaylist(widget.playlistId!, song.id);
      return await libraryCubit.searchByPlaylistId(widget.playlistId!, force: true);
    }

    final isDeleted = Platform.isAndroid
        ? await onAudioQuery.deleteSongs([song.id])
        : (song.data != null &&
            await audioPlayerHandler<FileManagementService>().deleteFile(File(song.data!)));

    if (!isDeleted) {
      SnackbarService.instance.showSnackbar(
        message: 'Error when deleting',
        backgroundColor: Colors.red,
      );
      return;
    }

    await playbackService.removeFromQueue(song);
    if (albumId != null &&
        libraryState.albumCollection[albumId]?.length == 1 &&
        await imageFile.exists()) {
      imageFile.delete();
    }

    libraryCubit.getAllSongs();
    if (albumId != null) libraryCubit.searchByAlbumId(albumId, force: true);
    if (artistId != null) libraryCubit.searchByArtistId(artistId, force: true);

    if (mounted) Navigator.pop(context);
    SnackbarService.instance.showSnackbar(message: 'Successfully removed');
  }

  @override
  Widget build(BuildContext context) {
    final songPlayed = widget.song;
    final onAudioQuery = audioPlayerHandler.get<MusicQuerySelector>();
    final favoritesState = context.watch<FavoritesCubit>().state;
    final libraryState = context.watch<LibraryCubit>().state;
    final audioControlCubit = context.watch<AudioControlCubit>();
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File(
      '${libraryState.appDirectory}/${songPlayed.albumId}.jpg',
    );
    final isFavoriteSong = favoritesState.isFavoriteSong(songPlayed.id);

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: AppTheme.surfaceColor,
      ),
      child: OrientationBuilder(
        builder: (_, orientation) => Stack(
        children: [
          ListView(
            shrinkWrap: true,
            physics: orientation == Orientation.portrait
                ? const NeverScrollableScrollPhysics()
                : const ScrollPhysics(),
            children: [
              const SizedBox(height: 70),
              // ── Group 1: Queue actions ────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.replay_outlined,
                    color: AppTheme.lightTextColor),
                title: const Text('Play next'),
                onTap: _playNext,
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
              if (libraryState.playLists.isNotEmpty && Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.playlist_add,
                      color: AppTheme.lightTextColor),
                  title: const Text('Add to playlist'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (_, setInnerState) => AlertDialog(
                          backgroundColor: AppTheme.surfaceColor,
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
              // ── Group 2: Navigation ───────────────────────────────────────
              ListTile(
                leading: const Icon(Icons.album_outlined,
                    color: AppTheme.lightTextColor),
                title: const Text('Go to album'),
                onTap: _goToAlbum,
              ),
              ListTile(
                leading: const Icon(Icons.person_outlined,
                    color: AppTheme.lightTextColor),
                title: const Text('Go to artist'),
                onTap: _goToArtist,
              ),
              ListTile(
                leading: const Icon(Icons.youtube_searched_for,
                    color: AppTheme.lightTextColor),
                title: const Text('Find on YouTube'),
                onTap: _findOnYoutube,
              ),
              const Divider(color: AppTheme.lightTextColor, height: 1),
              // ── Group 3: Info & file actions ──────────────────────────────
              ListTile(
                leading: const Icon(Icons.info_outline,
                    color: AppTheme.lightTextColor),
                title: const Text('Details'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => SongDetailsDialog(song: widget.song),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.share,
                    color: AppTheme.lightTextColor),
                title: const Text('Share'),
                onTap: _shareAudio,
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
                  onTap: _deleteSong,
                ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
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
                      '${songPlayed.artist.valueEmpty('No Artist')} • ${duration.timeString}',
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
      )
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
