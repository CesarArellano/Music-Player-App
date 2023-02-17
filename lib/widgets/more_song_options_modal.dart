import 'dart:io';


import 'package:flutter/material.dart';
import 'package:focus_music_player/audio_player_handler.dart';
import 'package:focus_music_player/helpers/format_extension.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:focus_music_player/providers/audio_control_provider.dart';
import 'package:focus_music_player/widgets/song_details_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';
import 'custom_list_tile.dart';

class MoreSongOptionsModal extends StatefulWidget {
  const MoreSongOptionsModal({
    super.key,
    required this.song,
  });

  final SongModel song;

  @override
  State<MoreSongOptionsModal> createState() => _MoreSongOptionsModalState();
}

class _MoreSongOptionsModalState extends State<MoreSongOptionsModal> {

  @override
  Widget build(BuildContext context) {
    final songPlayed = widget.song;
    final audioPlayer = audioPlayerHandler.get<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final duration = Duration(milliseconds: widget.song.duration ?? 0);
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final isFavoriteSong = musicPlayerProvider.isFavoriteSong(songPlayed.id);

    return OrientationBuilder(
      builder:(_, orientation) => Stack(
        children: [
          ListView(
            shrinkWrap: true,
            physics: orientation == Orientation.portrait ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
            children: [
              const SizedBox(height: 70),
              ListTile(
                leading: const Icon(Icons.replay_outlined, color: AppTheme.lightTextColor,),
                title: const Text('Play next'),
                onTap: () {
                  final currentIndex = audioControlProvider.currentIndex;
    
                  if( currentIndex == musicPlayerProvider.currentPlaylist.length - 1 ) {
                    return _addToQueue(
                      audioPlayer: audioPlayer,
                      musicPlayerProvider: musicPlayerProvider,
                      audioControlProvider: audioControlProvider,
                      song: songPlayed,
                    );
                  }
    
                  List<SongModel> tempList =  [ ...musicPlayerProvider.currentPlaylist ]..insert(
                    currentIndex + 1,
                    songPlayed
                  );
                  musicPlayerProvider.currentPlaylist = tempList;
                  MusicActions.openAudios(
                    audioPlayer: audioPlayer,
                    index: currentIndex,
                    seek: audioControlProvider.currentDuration,
                    audioControlProvider: audioControlProvider,
                    musicPlayerProvider: musicPlayerProvider
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
                  audioControlProvider: audioControlProvider,
                  song: songPlayed
                ),
              ),
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
            ],
          ),
          
          Container(
            color: AppTheme.primaryColor,
            child: Column(
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
              ],
            ),
          )
        ],
      ),
    );
  }

  void _addToQueue({
    required SongModel song,
    required AudioPlayer audioPlayer,
    required MusicPlayerProvider musicPlayerProvider,
    required AudioControlProvider audioControlProvider,
  }) {
    musicPlayerProvider.currentPlaylist = [ ...musicPlayerProvider.currentPlaylist, song ];
    MusicActions.openAudios(
      audioPlayer: audioPlayer,
      audioControlProvider: audioControlProvider,
      musicPlayerProvider: musicPlayerProvider,
      index: audioControlProvider.currentIndex,
      seek: audioControlProvider.currentDuration
    );
    Navigator.pop(context);
  }
}