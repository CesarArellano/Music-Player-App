import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_query_selector/music_query_selector.dart';

import '../../cubits/cubits.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../screens.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends State<AlbumsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final libraryState = context.watch<LibraryCubit>().state;
    final albumList = libraryState.albumList;

    return libraryState.isLoadingCatalogue
        ? CustomLoader(isCreatingArtworks: false)
        : albumList.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                child: OrientationBuilder(
                  builder: (_, orientation) => GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          orientation == Orientation.landscape ? 4 : 2,
                      mainAxisExtent: 230,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: albumList.length,
                    itemBuilder: (_, int i) {
                      final album = albumList[i];
                      final imageFile = File(
                        '${libraryState.appDirectory}/${album.id}.jpg',
                      );

                      return RippleTile(
                        borderRadius: BorderRadius.circular(AppTheme.artworkRadius),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTheme.artworkRadius),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ArtworkFileImage(
                                artworkId: album.id,
                                artworkType: ArtworkType.ALBUM,
                                width: double.maxFinite,
                                height: 174,
                                imageFile: imageFile,
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
                                child: Text(
                                  album.album,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                                child: Text(
                                  '${album.numOfSongs} ${album.numOfSongs > 1 ? 'songs' : 'song'}',
                                  style: const TextStyle(
                                    color: AppTheme.lightTextColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AlbumSelectedScreen(albumSelected: album),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            : const Center(
                child: Text(
                  'No Albums',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              );
  }
}
