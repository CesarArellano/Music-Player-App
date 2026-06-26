import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../audio_player_handler.dart';
import '../../cubits/cubits.dart';
import '../../services/snackbar_service.dart';
import '../../widgets/widgets.dart';
import '../playlist_selected_screen.dart';

class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
    final libraryState = context.watch<LibraryCubit>().state;
    final playlists = libraryState.playLists;

    return libraryState.isLoading
        ? CustomLoader(isCreatingArtworks: libraryState.isCreatingArtworks)
        : playlists.isNotEmpty
            ? OrientationBuilder(
                builder: (_, orientation) => GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 2 : 1,
                    childAspectRatio: 5.5,
                  ),
                  itemCount: playlists.length,
                  itemBuilder: (_, int i) {
                    final playlist = playlists[i];

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 15),
                      title: Text(
                        playlist.playlist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                      subtitle: Text(playlist.numOfSongs.toString()),
                      leading: ArtworkImage(
                        artworkId: playlist.id,
                        type: ArtworkType.PLAYLIST,
                        width: 55,
                        height: 55,
                        radius: BorderRadius.circular(2.5),
                        size: 250,
                      ),
                      onLongPress: () async {
                        final libraryCubit =
                            context.read<LibraryCubit>();
                        final removed =
                            await onAudioQuery.removePlaylist(playlist.id);
                        if (removed) {
                          if (!mounted) return;
                          SnackbarService.instance.showSnackbar(
                            message:
                                'The ${playlist.playlist} playlist was successfully removed!',
                          );
                          libraryCubit.refreshPlaylist();
                        }
                      },
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlaylistSelectedScreen(playlist: playlist),
                        ),
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text(
                  'No Playlists',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
  }
}
