import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focus_music_player/helpers/music_actions.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../helpers/custom_snackbar.dart';
import '../helpers/null_extension.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'screens.dart';
import 'tabs/favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSnackbarActive = false;

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    
    return WillPopScope(
      onWillPop: () async {
        if( _isSnackbarActive ) {
          audioPlayerHandler<AudioPlayer>().stop();
          audioPlayerHandler<AudioPlayer>().dispose();
          SystemNavigator.pop();
          return true;
        }

        _isSnackbarActive = true;
        
        showSnackbar(
          context: context,
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
        ).closed.then((_) => _isSnackbarActive = false);

        await Future.delayed(const Duration(seconds: 4));
        return false;
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          systemNavigationBarColor: AppTheme.primaryColor,
        ),
        child: DefaultTabController(
          length: 5,
          child: Scaffold(
            body: const _Body(),
            floatingActionButton: ( musicPlayerProvider.songList.isNotEmpty )
            ? FloatingActionButton(
                heroTag: 'fab',
                backgroundColor: AppTheme.accentColor,
                onPressed: musicPlayerProvider.isCreatingArtworks
                  ? null
                  : () {
                    int index = Random().nextInt(musicPlayerProvider.songList.length);
                    final song = musicPlayerProvider.songList[index];
                    MusicActions.songPlayAndPause(
                      context,
                      song,
                      TypePlaylist.songs,
                      heroId: 'songs-${ song.id }',
                      activateShuffle: true,
                    );
                  },
                child: musicPlayerProvider.isCreatingArtworks 
                  ? const CircularProgressIndicator(color: Colors.black,)
                  : const Icon( Icons.shuffle, color: Colors.black)
              )
            : null,
            bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title.value() ).isEmpty)
              ? null
              : const CurrentSongTile()
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: ( _, innerBoxIsScrolled ) {
        return <Widget> [
          _CustomAppBar( forceElevated: innerBoxIsScrolled ),
        ];
      },
      body: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: const TabBarView(
          children: <Widget>[
            SongsScreen(),
            AlbumsScreen(),
            ArtistScreen(),
            FavoriteScreen(),
            GenresScreen(),
          ],
        ),
      ),
    );
  }
}

class _CustomAppBar extends StatefulWidget {
  const _CustomAppBar({
    Key? key,
    required this.forceElevated,
  }) : super(key: key);
  final bool forceElevated;

  @override
  State<_CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<_CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);

    return SliverAppBar(
      forceElevated: widget.forceElevated,
      title: const Text('Focus Music Player'),
      pinned: true,
      floating: true,
      snap: true,
      shape: const Border(bottom: BorderSide(color: Colors.white24)),
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
          icon: const Icon(Icons.more_vert, color: AppTheme.lightTextColor),
          tooltip: 'More options',
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Share App', style: TextStyle(color: Colors.black)),
              onTap: () async {
                await Share.share("Hey, I Recommend this App fopr you. It's Most Stylish MP3 Music Player for your Android Device You would definitely like it.Please Try it Out. https://github.com/CesarArellano/Music-Player-App");
              },
            ),
            PopupMenuItem(
              child: const Text('Scan media', style: TextStyle(color: Colors.black)),
              onTap: () async {
                await _getAllSongs(
                  context: context,
                  musicPlayerProvider: musicPlayerProvider,
                );
                
                if(!mounted ) return;
                
                showSnackbar(context: context, message: 'Task successfully completed');
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

