import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:on_audio_query/on_audio_query.dart' show SongModel;
import 'package:provider/provider.dart';

import '../../helpers/music_actions.dart';
import '../../providers/music_player_provider.dart';
import '../../share_prefs/user_preferences.dart';
import '../../widgets/widgets.dart';

class SongsScreen extends StatefulWidget {
  
  const SongsScreen({Key? key}) : super(key: key);

  @override
  State<SongsScreen> createState() => _SongsScreenState();
}

class _SongsScreenState extends State<SongsScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    initSong();
    super.initState();
  }

  void initSong() {
    WidgetsBinding.instance.addPostFrameCallback(( _ ) {
      Future.delayed(const Duration(milliseconds: 400), () {
        final int lastSongId = UserPreferences().lastSongId;
        final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
        
        if( lastSongId == 0 ) return;
          
        musicPlayerProvider.songPlayed = musicPlayerProvider.songList.firstWhere(
          (song) => song.id == lastSongId,
          orElse: () => SongModel({ '_id': 0 })
        );

        if( musicPlayerProvider.songPlayed.id == 0 ) return;
        
        MusicActions.initSongs(context, musicPlayerProvider.songPlayed, 'current-song-${ musicPlayerProvider.songPlayed.id }');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songList = musicPlayerProvider.songList;

    return ( musicPlayerProvider.isLoading )
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : songList.isNotEmpty
        ? ListView.builder(
          itemCount: songList.length,
          itemBuilder: ( _, int i ) {
            final song = songList[i];
            final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
            final heroId = 'songs-${ song.id }';
            
            return RippleTile(
              child: CustomListTile(
                title: song.title.value(),
                subtitle: song.artist.valueEmpty('No Artist'),
                artworkId: song.id,
                imageFile: imageFile,
                tag: heroId,
              ),
              onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.songs, heroId: heroId),
              onLongPress: () {
                showModalBottomSheet(
                  context: context,
                  builder:( _ ) => MoreSongOptionsModal(song: song)
                );
              },
            );
          } 
        )
      : const Center( 
        child: Text(
          'No Songs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        )
      );
  }
}