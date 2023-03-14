import 'package:flutter/material.dart';
import 'package:focus_music_player/audio_player_handler.dart';
import 'package:focus_music_player/screens/playlist_selected_screen.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../helpers/helpers.dart';
import '../../providers/music_player_provider.dart';
import '../../widgets/widgets.dart';

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
    final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final playlists = musicPlayerProvider.playLists;

    return musicPlayerProvider.isLoading
      ? CustomLoader(isCreatingArtworks: musicPlayerProvider.isCreatingArtworks)
      : playlists.isNotEmpty 
        ? OrientationBuilder(
          builder: ( _, orientation ) => GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ( orientation == Orientation.landscape ) ?  2 : 1,
              childAspectRatio: 5.5
            ),
            itemCount: playlists.length,
            itemBuilder: ( _, int i ) {
              final playlist = playlists[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                title: Text(playlist.playlist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w400),),
                subtitle: Text(playlist.numOfSongs.toString()),
                onLongPress: () async {
                  final resp = await onAudioQuery.removePlaylist(playlist.id);
                  if( resp ) {
                    if( !mounted ) return;
                    Helpers.showSnackbar(
                      message: 'The ${ playlist.playlist } playlist was successfully removed!'
                    );
                    musicPlayerProvider.refreshPlaylist();
                  }
                },
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlaylistSelectedScreen( playlist: playlist))
                  );
                },
                leading: ArtworkImage(
                  artworkId: playlist.id,
                  type: ArtworkType.PLAYLIST,
                  width: 55,
                  height: 55,
                  radius: BorderRadius.circular(2.5),
                  size: 250,
                ),
              );
            } 
          )
        )
      : const Center( 
        child: Text('No Playlists', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
      );
  }
}