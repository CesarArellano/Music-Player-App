import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/audio_player_handler.dart';
import 'package:music_player_app/widgets/custom_list_tile.dart';
import 'package:music_player_app/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/custom_snackbar.dart';
import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';

class MoreSongOptionsModal extends StatefulWidget {
  const MoreSongOptionsModal({
    super.key,
    required this.song
  });

  final SongModel song;

  @override
  State<MoreSongOptionsModal> createState() => _MoreSongOptionsModalState();
}

class _MoreSongOptionsModalState extends State<MoreSongOptionsModal> {
  int? playListId;

  @override
  Widget build(BuildContext context) {
    final songPlayed = widget.song;
    final onAudioQuery = audioPlayerHandler.get<OnAudioQuery>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File(MusicActions.getArtworkPath(widget.song.data) ?? '');
    final isFavoriteSong = musicPlayerProvider.isFavoriteSong(songPlayed.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomListTile(
          artworkId: songPlayed.id,
          title: songPlayed.title ?? '',
          subtitle: '${ songPlayed.artist ?? 'No Artist' } • ${ duration.inMinutes }:${ duration.inSeconds }',
          imageFile: imageFile,
          trailing: IconButton(
            onPressed: () {
              List<String> favoriteSongList = [ ...musicPlayerProvider.favoriteSongList ];
              List<SongModel> favoriteList = [ ...musicPlayerProvider.favoriteList ];

              if( isFavoriteSong ) {
                favoriteList.removeWhere(((song) => song.id == songPlayed.id));
                favoriteSongList.removeWhere(((songId) => songId == songPlayed.id.toString()));
              } else {
                final index = musicPlayerProvider.songList.indexWhere((song) => song.id == songPlayed.id);
                favoriteList.add( musicPlayerProvider.songList[index] );
                favoriteSongList.add(songPlayed.id.toString());
              }

              musicPlayerProvider.favoriteList = favoriteList;
              musicPlayerProvider.favoriteSongList = favoriteSongList;
              UserPreferences().favoriteSongList = favoriteSongList;
            },
            icon: Icon( isFavoriteSong ? Icons.favorite : Icons.favorite_border)
          ),
        ),
        const Divider(color: AppTheme.lightTextColor, height: 1),
        if( musicPlayerProvider.playLists.isNotEmpty )
          ListTile(
            leading: const Icon(Icons.playlist_add, color: AppTheme.lightTextColor,),
            title: const Text('Add to Playlist'),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (_, setInnerState) {
                        return AlertDialog(
                          backgroundColor: AppTheme.primaryColor,
                          title: const Text('Add to playlist'),
                          content: DropdownButton<int?>(
                            isExpanded: true,
                            value: playListId,
                            dropdownColor: AppTheme.primaryColor,
                            hint: const Text('Seleccionar una playlist', style: TextStyle(color: Colors.white)),
                            items: musicPlayerProvider.playLists.map((e) => DropdownMenuItem<int?>(value: e.id,child: Text(e.playlist, style: const TextStyle(color: Colors.white)),)).toList(),
                            onChanged: (int? value) => setInnerState(() => playListId = value),
                          ),
                          actions: [
                            TextButton(
                              onPressed: playListId == null
                                ? null
                                : () {
                                  onAudioQuery.addToPlaylist(playListId!, widget.song.id);
                                  musicPlayerProvider.refreshPlaylist();
                                  Navigator.pop(context);
                                },
                              child: const Text('Add')
                            )
                          ],
                        );
                    }
                  );
                }
              );
            },
          ),
        ListTile(
          leading: const Icon(Icons.share, color: AppTheme.lightTextColor,),
          title: const Text('Share Audio'),
          onTap: () async {
            Directory appDocDir = await getApplicationDocumentsDirectory();
            File imageTempFile = File('${ appDocDir.path }/${ widget.song.title ?? ''}.jpg');
            List<XFile> filesToShare = [ XFile(widget.song.data) ];
            final artworkBytes = await OnAudioQuery().queryArtwork(widget.song.id, ArtworkType.AUDIO, size: 500);
            if( artworkBytes != null) {
              final imageFile = XFile((await imageTempFile.writeAsBytes(artworkBytes)).path);
              filesToShare.add(imageFile);
            }
            
            await Share.shareXFiles(
              filesToShare,
              text: 'I share you the song ${ widget.song.title ?? '' }'
            );

            MusicActions.deleteFile(imageTempFile.path);
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: AppTheme.lightTextColor,),
          title: const Text('Details'),
          onTap: () {
            showDialog(context: context, builder: (_) => SongDetailsDialog(song: widget.song));
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppTheme.lightTextColor,),
          title: const Text('Delete from device'),
          onTap: () async {
            final isDeleted = await MusicActions.deleteFile(widget.song.data);
            
            if( !context.mounted ) return;

            Navigator.pop(context);

            if( isDeleted ) {
              Provider.of<MusicPlayerProvider>(context, listen: false).getAllSongs();
              return showSnackbar(
                context: context,
                message: 'Se eliminó exitosamente'
              );
            }
            showSnackbar(
              context: context,
              message: 'Error al eliminar',
              backgroundColor: Colors.red
            );
          },
        ),
      ],
    );
  }
}

extension ContextExtensions on BuildContext {
  bool get mounted {
    try {
      widget;
      return true;
    } catch (e) {
      return false;
    }
  }
}