import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../extensions/extensions.dart';
import '../helpers/helpers.dart';
import '../helpers/music_actions.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'screens.dart';
import 'tabs/favorite_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    
    return WillPopScope(
      onWillPop: () async => _onWillPop(context),
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          body: const _Body(),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab',
            backgroundColor: AppTheme.accentColor,
            onPressed: musicPlayerProvider.isCreatingArtworks
                ? null
                : () => _shuffleAction(context, musicPlayerProvider), 
            child: musicPlayerProvider.isCreatingArtworks 
                ? const CircularProgressIndicator(color: Colors.black,)
                : const Icon( Icons.shuffle, color: Colors.black)
          ),
          bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title.value() ).isEmpty)
            ? null
            : const CurrentSongTile()
        ),
      ),
    );
  }

  // Future<void> addPlaylist(MusicPlayerProvider musicPlayerProvider) async {
  //   final CreatePlaylistResp dialogResp = await showDialog<CreatePlaylistResp>(
  //     context: context,
  //     builder: (_) => CreatePlaylistDialog()
  //   ) ?? const CreatePlaylistResp(isCancel: true);

  //   if( dialogResp.isCancel ) return;

  //   final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
  //   await onAudioQuery.createPlaylist(dialogResp.playlistName.value());
    
  //   if( !mounted ) return;

  //   Helpers.showSnackbar(
  //     message: 'The ${ dialogResp.playlistName.value() } playlist was successfully added!'
  //   );
    
  //   musicPlayerProvider.refreshPlaylist();
  // }

  void _shuffleAction(BuildContext context, MusicPlayerProvider musicPlayerProvider) {
    int index = Random().nextInt(musicPlayerProvider.songList.length);
    final song = musicPlayerProvider.songList[index];
    MusicActions.songPlayAndPause(
      context,
      song,
      PlaylistType.songs,
      heroId: 'songs-${ song.id }',
      activateShuffle: true,
    );
  }

  Future<bool> _onWillPop(BuildContext context) async {
    bool isSnackbarActive = context.read<UIProvider>().isSnackbarActive;
    if( isSnackbarActive ) {
      audioPlayerHandler<AudioPlayer>().stop();
      audioPlayerHandler<AudioPlayer>().dispose();
      SystemNavigator.pop();
      return true;
    }

    isSnackbarActive = true;
    
    Helpers.showSnackbar(
      message: 'Please back again to exit',
      snackBarAction: SnackBarAction(
        label: 'EXIT',
        textColor: AppTheme.accentColor,
        onPressed: () {
          audioPlayerHandler<AudioPlayer>().stop();
          audioPlayerHandler<AudioPlayer>().dispose();
          SystemNavigator.pop();
        },
      )
    ).closed.then((_) => isSnackbarActive = false);

    await Future.delayed(const Duration(seconds: 4));
    return false;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
  }): super(key: key);

  @override
  Widget build(BuildContext context) {

    return NestedScrollView(
      headerSliverBuilder: (_, __) => [ const _CustomAppBar() ],
      body: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: const TabBarView(
          children: <Widget>[
            SongsScreen(),
            AlbumsScreen(),
            ArtistScreen(),
            PlaylistsScreen(),
            FavoriteScreen(),
            GenresScreen(),
          ],
        ),
      ),
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return SliverAppBar(
      pinned: true,
      floating: true,
      title: const Text('Focus Music Player'),
      shape: const Border(bottom: BorderSide(color: Colors.white54)),
      bottom: const TabBar(
        isScrollable: true,
        indicatorColor: AppTheme.accentColor,
        labelColor: Colors.white,
        labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelColor: AppTheme.lightTextColor,
        indicatorWeight: 3.0,
        tabs: <Widget> [
          Tab(text: 'Songs'),
          Tab(text: 'Albums'),
          Tab(text: 'Artists'),
          Tab(text: 'Playlist'),
          Tab(text: 'Favorites'),
          Tab(text: 'Genres'),
        ], 
        
      ),
      actions: <Widget>[
        IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.search),
          color: AppTheme.lightTextColor,
          onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          tooltip: 'Search music',
        ),
        PopupMenuButton(
          color: Colors.white,
          icon: const Icon(Icons.more_vert, color: AppTheme.lightTextColor),
          tooltip: 'More options',
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Share App', style: TextStyle(color: Colors.black)),
              onTap: () async {
                await Share.share("Hey, I Recommend this App for you. It's Most Stylish MP3 Music Player for your Android Device You would definitely like it.Please Try it Out. https://github.com/CesarArellano/Music-Player-App");
              },
            ),
            PopupMenuItem(
              child: const Text('Scan media', style: TextStyle(color: Colors.black)),
              onTap: () async {
                final musicPlayerProvider = context.read<MusicPlayerProvider>();

                await _getAllSongs(
                  context: context,
                  musicPlayerProvider: musicPlayerProvider,
                );

                Helpers.showSnackbar(message: 'Task successfully completed');
              }
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _getAllSongs({ 
    required MusicPlayerProvider musicPlayerProvider,
    required BuildContext context,
    bool forceCreatingArtworks = false
  }) async {
    await musicPlayerProvider.getAllSongs(forceCreatingArtworks: forceCreatingArtworks);
  }
}

