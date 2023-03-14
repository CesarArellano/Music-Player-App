import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:focus_music_player/providers/ui_provider.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../../extensions/extensions.dart';
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
        final uiProvider = Provider.of<UIProvider>(context, listen: false);
        uiProvider.dominantColorCollection = UserPreferences().dominantColorCollection;
        musicPlayerProvider.currentPlaylist = musicPlayerProvider.songList;
        MusicActions.initStreams(context);
        
        if( lastSongId == 0 ) return;
          
        musicPlayerProvider.songPlayed = musicPlayerProvider.songList.firstWhere(
          (song) => song.id == lastSongId,
          orElse: () => SongModel({ '_id': 0 })
        );

        if( musicPlayerProvider.songPlayed.id == 0 ) return;
        
        MusicActions.initSongs(
          context,
          musicPlayerProvider.songPlayed,
          heroId: 'current-song-${ musicPlayerProvider.songPlayed.id }'
        );
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
        ? OrientationBuilder(
          builder: (context, orientation) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ( orientation == Orientation.landscape ) ?  2 : 1,
              childAspectRatio: 5.5
            ),
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
                onTap: () => MusicActions.songPlayAndPause(context, song, PlaylistType.songs, heroId: heroId),
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder:( _ ) => MoreSongOptionsModal(song: song)
                  );
                },
              );
            } 
          ),
        )
      : const Center( 
        child: Text(
          'No Songs',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
        )
      );
  }
}