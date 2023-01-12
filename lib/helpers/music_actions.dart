


import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../screens/song_played_screen.dart';
import '../theme/app_theme.dart';

enum TypePlaylist {
  songs,
  album,
  artist,
  genre,
  playlist,
}
class MusicActions {

  static void songPlayAndPause(BuildContext context, SongModel song, TypePlaylist type, { id = 0 }) async {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);

    musicPlayerProvider.currentPlaylist = ( type == TypePlaylist.songs )
      ? musicPlayerProvider.songList
      : ( type == TypePlaylist.album)
        ? musicPlayerProvider.albumCollection[id]!
        : ( type == TypePlaylist.artist) 
          ? musicPlayerProvider.artistCollection[id]!
          : ( type == TypePlaylist.playlist) 
            ? musicPlayerProvider.playlistCollection[id]!
            : musicPlayerProvider.genreCollection[id]!;

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );

    if( musicPlayerProvider.songPlayed.title != song.title ) {
      audioPlayer.stop();
      audioPlayer.open(
        Playlist(
          audios: [
            ...musicPlayerProvider.currentPlaylist.map((song) => Audio.file(
                song.data,
                metas: Metas(
                  album: song.album,
                  artist: song.artist,
                  title: song.title,
                  id: song.id.toString(),
                  image: MetasImage.file('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg'),
                  onImageLoadFail: const MetasImage.asset('assets/images/background.jpg'),
                )
              )
            )
          ],
          startIndex: index,
        ),
        showNotification: true,
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
        playInBackground: PlayInBackground.enabled,
        notificationSettings: NotificationSettings(
          customStopAction: (player) {
            player.stop();
            player.dispose();
            if( Platform.isAndroid ) {
              SystemNavigator.pop();
            } else {
              exit(0);
            }
          },
        )
      );
      
      audioPlayer.currentPosition.listen((duration) {
        audioControlProvider.currentDuration = duration;
      });

      audioPlayer.playlistAudioFinished.listen((playing) {
        if( musicPlayerProvider.songPlayed.title == song.title || !playing.hasNext ) return;
        
        audioControlProvider.currentIndex = playing.playlist.nextIndex ?? audioControlProvider.currentIndex + 1;
        musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[ audioControlProvider.currentIndex ];
      });

      musicPlayerProvider.songPlayed = song;
    } else {
      audioPlayer.seek( const Duration( seconds: 0 ));
    }

    PageTransitions(
      context: context,
      child: const SongPlayedScreen(),
      animation: AnimationType.fadeIn,
    );
  }

  static void showCurrentPlayList(BuildContext context, ){
    final audioPlayer = audioPlayerHandler.get<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final currentSong = audioPlayer.getCurrentAudioTitle;

    showModalBottomSheet(
      context: context,
      builder: ( ctx ) => ListView.builder(
        shrinkWrap: true,
        itemCount: audioPlayer.playlist?.audios.length,
        itemBuilder: (_, int i) {
          final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
          final audio = audioPlayer.playlist?.audios[i];
          final currentColor = ( currentSong == audio?.metas.title ) ? AppTheme.accentColor : Colors.white;
          
          return ListTile(
            leading: Icon( Icons.music_note, color: currentColor ),
            title: Text(audio!.metas.title!, maxLines: 1, style: TextStyle(color: currentColor)),
            subtitle: Text(audio.metas.artist!, maxLines: 1, style: TextStyle(color: currentColor)),
            onTap: () {
              audioPlayer.playlistPlayAtIndex(i);
              audioControlProvider.currentIndex = i;
              musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[i];
              Navigator.pop(ctx);
            },            
          );
        }
      ),
    );
  }

  static String? getArtworkPath(String uri) {
    if( uri.isEmpty ) return null;
    
    final pathSegments = uri.split('/');
    String finalPath = '';
    
    for(int i = 0; i < pathSegments.length; i++) {
      if( i + 1 == pathSegments.length ) break;
      finalPath += '/${ pathSegments[i] }';
    }
    
    return '$finalPath/cover.jpg';   
  }

  static Future<ImageProvider<Object>?> getSpecificArtwork(BuildContext context) async {
    final songPlayed = Provider.of<MusicPlayerProvider>(context, listen: false).songPlayed;
    final OnAudioQuery onAudioQuery = audioPlayerHandler.get();
    final foundArtwork = await onAudioQuery.queryArtwork(songPlayed.id, ArtworkType.AUDIO);
    
    if (foundArtwork != null ) {
      return MemoryImage(foundArtwork);
    }
    
    return const AssetImage('assets/images/background.jpg');
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      final permissionStatus = await Permission.manageExternalStorage.request();
      final file = File(filePath);

      if( permissionStatus.isGranted && await file.exists()) {
        await file.delete(recursive: true);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
}