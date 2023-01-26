import 'dart:io';


import 'package:flutter/material.dart';
import 'package:focus_music_player/audio_player_handler.dart';
import 'package:focus_music_player/helpers/format_extension.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:focus_music_player/providers/audio_control_provider.dart';
import 'package:focus_music_player/widgets/custom_list_tile.dart';
import 'package:focus_music_player/widgets/song_details_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
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
  int? playListId;

  @override
  Widget build(BuildContext context) {
    final songPlayed = widget.song;
    final onAudioQuery = audioPlayerHandler.get<OnAudioQuery>();
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final isFavoriteSong = musicPlayerProvider.isFavoriteSong(songPlayed.id);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomListTile(
          artworkId: songPlayed.id,
          title: songPlayed.title.value(),
          subtitle: '${ songPlayed.artist.valueEmpty('No Artist') } • ${ duration.getTimeString() }',
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
        ListTile(
          leading: const Icon(Icons.replay_outlined, color: AppTheme.lightTextColor,),
          title: const Text('Play next'),
          onTap: () {
            final currentIndex = audioControlProvider.currentIndex;

            if( currentIndex == musicPlayerProvider.currentPlaylist.length - 1 ) {
              return _addToQueue(
                audioPlayer: audioPlayer,
                musicPlayerProvider: musicPlayerProvider,
                song: songPlayed
              );
            }

            List<SongModel> tempList =  [ ...musicPlayerProvider.currentPlaylist ]..insert(
              currentIndex + 1,
              songPlayed
            );
            musicPlayerProvider.currentPlaylist = tempList;

            audioPlayer.sequenceState?.effectiveSequence.insert(
              currentIndex + 1, 
              AudioSource.file(
                songPlayed.data,
                tag: MediaItem(
                  id: songPlayed.id.toString(),
                  title: songPlayed.title.value(),
                  artist: songPlayed.artist,
                  album: songPlayed.album,
                  artUri: Uri.file('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg'),
                )
              )
            );

            Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.library_add_rounded, color: AppTheme.lightTextColor,),
          title: const Text('Add to playing queue'),
          onTap: () => _addToQueue(
            audioPlayer: audioPlayer,
            musicPlayerProvider: musicPlayerProvider,
            song: songPlayed
          ),
        ),
        if( musicPlayerProvider.playLists.isNotEmpty ) ...[
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
          const Divider(color: AppTheme.lightTextColor, height: 1),
        ],
        ListTile(
          leading: const Icon(Icons.share, color: AppTheme.lightTextColor,),
          title: const Text('Share Audio'),
          onTap: () async {
            List<XFile> filesToShare = [ XFile(songPlayed.data) ];

            if( await imageFile.exists() ) {
              filesToShare.add(XFile(imageFile.path));
            }

            await Share.shareXFiles(
              filesToShare,
              text: 'I share you the song ${ widget.song.title.value() }'
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline, color: AppTheme.lightTextColor,),
          title: const Text('Details'),
          onTap: () {
            showDialog(context: context, builder: (_) => SongDetailsDialog(song: widget.song));
          },
        ),
        if( !widget.disabledDeleteButton )
          ListTile(
            leading: Icon(widget.isPlaylist ? Icons.playlist_remove : Icons.delete_forever, color: AppTheme.lightTextColor,),
            title: Text(widget.isPlaylist ? 'Remove from this playlist' : 'Delete from device'),
            onTap: () async {
              final albumId = songPlayed.albumId;
              final artistId = songPlayed.artistId;

              if( widget.isPlaylist ) {
                onAudioQuery.removeFromPlaylist(widget.playlistId!, songPlayed.id);
                return await musicPlayerProvider.searchByPlaylistId(widget.playlistId!, force: true);
              }

              if( albumId != null ) {
                await musicPlayerProvider.searchByAlbumId(albumId);
                if( musicPlayerProvider.albumCollection[albumId]?.length == 1  && await imageFile.exists() ) {
                  MusicActions.deleteFile(imageFile);
                }
              }
              
              final isDeleted = await MusicActions.deleteFile(File(songPlayed.data));
              
              if( !mounted ) return;

              Navigator.pop(context);

              if( isDeleted ) {
                Provider.of<MusicPlayerProvider>(context, listen: false).getAllSongs();
                
                if( albumId != null ) {
                  await musicPlayerProvider.searchByAlbumId(albumId, force: true);
                }

                if( artistId != null ) {
                  await musicPlayerProvider.searchByArtistId(artistId, force: true);
                }

                if( !mounted ) return;
                
                showSnackbar(
                  context: context,
                  message: 'Successfully removed'
                );
                
                return;
              }
              showSnackbar(
                context: context,
                message: 'Error when deleting',
                backgroundColor: Colors.red
              );
            },
          ),
      ],
    );
  }

  void _addToQueue({
    required SongModel song,
    required AudioPlayer audioPlayer,
    required MusicPlayerProvider musicPlayerProvider
  }) {
    audioPlayer.sequenceState?.effectiveSequence.add(
      AudioSource.file(
        song.data,
        tag: MediaItem(
          id: song.id.toString(),
          title: song.title.value(),
          artist: song.artist,
          album: song.album,
          artUri: Uri.file('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg'),
        )
      )
    );
    musicPlayerProvider.currentPlaylist = [ ...musicPlayerProvider.currentPlaylist, song ];
    Navigator.pop(context);
  }
}