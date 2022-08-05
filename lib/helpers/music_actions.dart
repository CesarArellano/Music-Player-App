


import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:custom_page_transitions/custom_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
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
  genre
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
                image: MetasImage.file(song.uri ?? ''),
                onImageLoadFail: const MetasImage.asset('assets/images/background.jpg') 
              )
            ))
          ],
          startIndex: index,
        ),
        headPhoneStrategy: HeadPhoneStrategy.pauseOnUnplugPlayOnPlug,
        showNotification: true,
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
      animation: AnimationType.slideUp,
      duration: const Duration( milliseconds:  250 ),
      reverseDuration: const Duration( milliseconds:  250),
      curve: Curves.easeOut,
    );
  }

  static void showCurrentPlayList(BuildContext context, ){
    final audioPlayer = audioPlayerHandler.get<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final currentSong = audioPlayer.getCurrentAudioTitle;
    showModalBottomSheet(

      backgroundColor: AppTheme.primaryColor,
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
      )
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
}