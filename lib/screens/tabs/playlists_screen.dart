import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../providers/music_player_provider.dart';

class PlaylistsScreen extends StatefulWidget {
  
  const PlaylistsScreen({Key? key}) : super(key: key);

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final playlists = musicPlayerProvider.playLists;

    return musicPlayerProvider.isLoading
      ? const Center ( child: CircularProgressIndicator() )
      : playlists.isNotEmpty 
        ? ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: playlists.length,
          itemBuilder: ( _, int i ) {
            final playlist = playlists[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric( vertical: 10, horizontal: 15),
              title: Text(playlist.playlist),
              subtitle: Text(playlist.numOfSongs.toString()),
              onTap: () {
              },
              leading: QueryArtworkWidget(
                keepOldArtwork: true,
                id: playlist.id,
                type: ArtworkType.PLAYLIST,
              ),
            );
          } 
        )
      : const Center( 
        child: Text('No Playlists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
      );
  }
}