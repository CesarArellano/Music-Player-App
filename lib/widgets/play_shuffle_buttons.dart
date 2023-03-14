import 'dart:math';

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../helpers/music_actions.dart';
import 'custom_icon_text_button.dart';

class PlayShuffleButtons extends StatelessWidget {
  const PlayShuffleButtons({
    super.key,
    required this.id,
    required this.typePlaylist,
    required this.songList,
    required this.heroId,
  });

  final int id;
  final PlaylistType typePlaylist;
  final List<SongModel> songList;
  final String heroId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: SizedBox(
            height: 45,
            child: CustomIconTextButton(
              label: 'PLAY ALL',
              icon: Icons.play_arrow,
              onPressed: () => _playAllOrShuffle(context: context)
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 45,
            child: CustomIconTextButton(
              label: 'SHUFFLE',
              icon: Icons.shuffle,
              onPressed: () => _playAllOrShuffle(context: context,  activeShuffle: true)
            ),
          ),
        ),
      ],
    );
  }
  
  void _playAllOrShuffle({
    required BuildContext context,
    bool activeShuffle = false,
  }) {
    int index = 0;
    
    if( activeShuffle ) {
      index = Random().nextInt(songList.length);
    }

    final song = songList[index];

    MusicActions.songPlayAndPause(
      context,
      song,
      activateShuffle: activeShuffle,
      typePlaylist,
      id: id,
      heroId: '$heroId${ song.id }'
    );
  }
}