import 'dart:io';

import 'package:flutter/material.dart';
import 'package:music_player_app/widgets/artwork_image.dart';
import 'package:music_player_app/widgets/song_details_dialog.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../helpers/custom_snackbar.dart';
import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../theme/app_theme.dart';

class MoreSongOptionsModal extends StatelessWidget {
  const MoreSongOptionsModal({
    super.key,
    required this.song
  });

  final SongModel song;

  @override
  Widget build(BuildContext context) {
    final duration = Duration(milliseconds: song.duration ?? 0);
    final imageFile = File(MusicActions.getArtworkPath(song.data) ?? '');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          title: Text(song.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${ song.artist ?? 'No Artist' } • ${ duration.inMinutes }:${ duration.inSeconds.toString().substring(0,2) }', style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12)),                
          leading: imageFile.existsSync() 
            ? ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Image.file(
                imageFile,
                width: 55,
                height: 55,
                filterQuality: FilterQuality.low,
                gaplessPlayback: true,
              ),
            )
            : ArtworkImage(
              artworkId: song.id,
              type: ArtworkType.AUDIO,
              width: 55,
              height: 55,
              size: 250,
              radius: BorderRadius.circular(3),
            ),
        ),
        const Divider(color: AppTheme.lightTextColor, height: 1),
        ListTile(
          leading: const Icon(Icons.info_outline, color: AppTheme.lightTextColor,),
          title: const Text('Details'),
          onTap: () {
            showDialog(context: context, builder: (_) => SongDetailsDialog(song: song));
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppTheme.lightTextColor,),
          title: const Text('Delete from device'),
          onTap: () async {
            final isDeleted = await MusicActions.deleteFile(song.data);
            
            if( !context.mounted ) return;

            Navigator.pop(context);

            if( isDeleted ) {
              Provider.of<MusicPlayerProvider>(context, listen: false).getAllSongs();
              return showSnackbar(
                context: context,
                message: 'Se eliminó exitosamente'
              );
            }
            showSnackbar(
              context: context,
              message: 'Error al eliminar',
              backgroundColor: Colors.red
            );
          },
        ),
      ],
    );
  }
}

extension ContextExtensions on BuildContext {
  bool get mounted {
    try {
      widget;
      return true;
    } catch (e) {
      return false;
    }
  }
}