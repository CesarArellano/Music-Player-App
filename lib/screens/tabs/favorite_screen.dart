import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/cubits.dart';
import '../../extensions/extensions.dart';
import '../../helpers/music_actions.dart';
import '../../widgets/widgets.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final libraryState = context.watch<LibraryCubit>().state;
    final favoritesState = context.watch<FavoritesCubit>().state;
    final songList = favoritesState.favoriteList;

    return libraryState.isLoading
        ? CustomLoader(isCreatingArtworks: libraryState.isCreatingArtworks)
        : songList.isNotEmpty
            ? OrientationBuilder(
                builder: (_, orientation) => GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        orientation == Orientation.landscape ? 2 : 1,
                    childAspectRatio: 5.5,
                  ),
                  itemCount: songList.length,
                  itemBuilder: (_, int i) {
                    final song = songList[i];
                    final imageFile = File(
                      '${libraryState.appDirectory}/${song.albumId}.jpg',
                    );
                    final heroId = 'favorite-song-${song.id}';

                    return RippleTile(
                      onTap: () => MusicActions.songPlayAndPause(
                        context,
                        song,
                        PlaylistType.favorites,
                        heroId: heroId,
                      ),
                      onLongPress: () => showModalBottomSheet(
                        context: context,
                        builder: (_) => MoreSongOptionsModal(
                          song: song,
                          disabledDeleteButton: true,
                        ),
                      ),
                      child: CustomListTile(
                        title: song.title.value(),
                        subtitle: song.artist.valueEmpty('No Artist'),
                        imageFile: imageFile,
                        artworkId: song.id,
                        tag: heroId,
                      ),
                    );
                  },
                ),
              )
            : const Center(
                child: Text(
                  'No Favorites',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
  }
}
