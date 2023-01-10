import 'package:flutter/material.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:music_player_app/widgets/custom_icon_text_button.dart';
import 'package:on_audio_query/on_audio_query.dart';


class PlaylistSelectedScreen extends StatelessWidget {
  
  const PlaylistSelectedScreen({
    Key? key,
    required this.playlist,
  }) : super(key: key);
  
  final PlaylistModel playlist;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.lightTextColor),
          onPressed: () => Navigator.pop(context),
        ), 
        title: Text(playlist.playlist),
      ),
      body: playlist.numOfSongs <= 0 
        ? _EmptyList(playlist: playlist)
        : const SizedBox()
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