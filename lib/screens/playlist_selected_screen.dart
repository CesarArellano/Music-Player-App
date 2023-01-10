import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:music_player_app/widgets/custom_icon_text_button.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../widgets/artwork_image.dart';
import '../widgets/current_song_tile.dart';
import '../widgets/ripple_tile.dart';


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
  @override
  void initState() {
    super.initState();
    Provider.of<MusicPlayerProvider>(context, listen: false).searchByPlaylistId( widget.playlist.id );
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
      body: musicPlayerProvider.isLoading
        ? const Center( child: CircularProgressIndicator(color: Colors.white) )
        :  musicPlayerProvider.playlistCollection[widget.playlist.id]!.isEmpty
          ? _EmptyList(playlist: widget.playlist)
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: musicPlayerProvider.playlistCollection[widget.playlist.id]!.length,
              itemBuilder: (_, int i) {
                final song = musicPlayerProvider.playlistCollection[widget.playlist.id]![i];
                final imageFile = File(MusicActions.getArtworkPath(song.data) ?? '');
                
                return RippleTile(
                  child: ListTile(
                    leading: imageFile.existsSync()
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(2.5),
                        child: Image.file(
                          imageFile,
                          width: 50,
                          height: 50,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.low,
                        ),
                      )
                      : ArtworkImage(
                        artworkId: song.albumId ?? 1,
                        type: ArtworkType.ALBUM,
                        width: 50,
                        height: 50,
                        size: 250,
                        radius: BorderRadius.circular(2.5),
                      ),
                    title: Text(song.title ?? ''),
                    subtitle: Text(song.artist ?? 'No Artist')
                  ),
                  onTap: () {
                    MusicActions.songPlayAndPause(context, song, TypePlaylist.playlist, id: widget.playlist.id );
                  },
                );
              },
            ),
      bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title ?? '').isEmpty)
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