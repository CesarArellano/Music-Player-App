


import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_player_app/providers/ui_provider.dart';
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
  favorites
}
class MusicActions {

  static void songPlayAndPause(
    BuildContext context,
    SongModel song,
    TypePlaylist type, { 
      required String heroId,
      int id = 0,
    }
  ) async {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
    final uiProvider = Provider.of<UIProvider>(context, listen: false);
    uiProvider.currentHeroId = heroId;
    
    musicPlayerProvider.currentPlaylist = ( type == TypePlaylist.songs )
      ? musicPlayerProvider.songList
      : ( type == TypePlaylist.album)
        ? musicPlayerProvider.albumCollection[id]!
        : ( type == TypePlaylist.artist) 
          ? musicPlayerProvider.artistCollection[id]!
          : ( type == TypePlaylist.playlist) 
            ? musicPlayerProvider.playlistCollection[id]!
            : ( type == TypePlaylist.genre) 
              ? musicPlayerProvider.genreCollection[id]!
              : musicPlayerProvider.favoriteList;

    final index = musicPlayerProvider.currentPlaylist.indexWhere((songOfList) => songOfList.id == song.id );

    if( musicPlayerProvider.songPlayed.id != song.id ) {
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongPlayedScreen(
          playlistId: ( TypePlaylist.playlist == type ) ? id : null,
          isPlaylist: ( TypePlaylist.playlist == type ),
        )
      )
    );
  }

  static void showCurrentPlayList(BuildContext context, ){
    final audioPlayer = audioPlayerHandler.get<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      builder: ( ctx ) => ListView.builder(
        shrinkWrap: true,
        itemCount: audioPlayer.playlist?.audios.length,
        itemBuilder: (_, int i) {
          final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
          final audio = audioPlayer.playlist?.audios[i];
          final currentColor = ( musicPlayerProvider.songPlayed.id.toString() == audio?.metas.id ) ? AppTheme.accentColor : Colors.white;
          
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

  static Future<bool> createArtwork(File imageTempFile, int songId) async {
    final artworkBytes = await OnAudioQuery().queryArtwork(songId, ArtworkType.AUDIO, size: 500);
    
    if( artworkBytes != null ) {
      await imageTempFile.writeAsBytes(artworkBytes);
      return true;
    }

    return false;
  }

  static Future<bool> deleteFile(File file) async {
    try {
      final permissionStatus = await Permission.manageExternalStorage.request();

      if( permissionStatus.isGranted && await file.exists()) {
        await file.delete(recursive: true);
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // static String? getArtworkPath(String uri) {
  //   if( uri.isEmpty ) return null;
    
  //   final pathSegments = uri.split('/');
  //   String finalPath = '';
    
  //   for(int i = 0; i < pathSegments.length; i++) {
  //     if( i + 1 == pathSegments.length ) break;
  //     finalPath += '/${ pathSegments[i] }';
  //   }
    
  //   return '$finalPath/cover.jpg';   
  // }
}