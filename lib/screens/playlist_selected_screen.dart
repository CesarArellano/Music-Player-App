import 'dart:io';

import 'package:flutter/material.dart';
import 'package:focus_music_player/helpers/null_extension.dart';
import 'package:focus_music_player/theme/app_theme.dart';
import 'package:focus_music_player/widgets/custom_icon_text_button.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../widgets/widgets.dart';


class PlaylistSelectedScreen extends StatefulWidget {
  
  const PlaylistSelectedScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);
  
  final PlaylistModel playlist;

  @override
  State<PlaylistSelectedScreen> createState() => _PlaylistSelectedScreenState();
}

class _PlaylistSelectedScreenState extends State<PlaylistSelectedScreen> {
  
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getSongs();
  }
  
  void getSongs() {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await  musicPlayerProvider.searchByPlaylistId( widget.playlist.id, force: (musicPlayerProvider.playlistCollection[widget.playlist.id]?.length ?? 0) != widget.playlist.numOfSongs);
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ), 
        title: Text(widget.playlist.playlist),
      ),
      body: isLoading
        ? const Center( child: CircularProgressIndicator() )
        :  musicPlayerProvider.playlistCollection[widget.playlist.id]!.isEmpty
          ? _EmptyList(playlist: widget.playlist)
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ( musicPlayerProvider.playlistCollection[widget.playlist.id] ?? [] ).length,
              itemBuilder: (_, int i) {
                final song = musicPlayerProvider.playlistCollection[widget.playlist.id]![i];
                final imageFile = File('${ musicPlayerProvider.appDirectory }/${ song.albumId }.jpg');
                final heroId = 'playlist-song-${ song.id }';
                
                return RippleTile(
                  child: CustomListTile(
                    artworkId: song.id,
                    title: song.title.value(),
                    subtitle: song.artist.valueEmpty('No Artist'),
                    imageFile: imageFile,
                    tag: heroId,
                  ),
                  onTap: () => MusicActions.songPlayAndPause(context, song, TypePlaylist.playlist, id: widget.playlist.id, heroId: heroId),
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder:( _ ) => MoreSongOptionsModal(
                        song: song,
                        isPlaylist: true,
                        playlistId: widget.playlist.id,
                      )
                    );
                  },
                );
              },
            ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || musicPlayerProvider.songPlayed.title.value().isEmpty)
          ? null
          : const CurrentSongTile()
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({
    Key? key,
    required this.playlist,
  }) : super(key: key);

  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            maxRadius: 50,
            child: Icon(Icons.music_note_rounded, color: Colors.white54, size: 50),
          ),
          const SizedBox(height: 15),
          const Text('No songs', style: TextStyle(color: AppTheme.lightTextColor, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 15),
          SizedBox(
            width: 140,
            height: 50,
            child: CustomIconTextButton(
              label: 'Add songs',
              icon: Icons.add,
              onPressed: () {
                // final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
              },
            ),
          )
        ],
      ),
    );
  }
}