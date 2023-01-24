import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../helpers/custom_snackbar.dart';
import '../helpers/null_extension.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/create_playlist_dialog.dart';
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
          audioPlayerHandler<AssetsAudioPlayer>().stop();
          audioPlayerHandler<AssetsAudioPlayer>().dispose();
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
              audioPlayerHandler<AssetsAudioPlayer>().stop();
              audioPlayerHandler<AssetsAudioPlayer>().dispose();
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
          length: 6,
          child: Scaffold(
            body: const _Body(),
            floatingActionButton: FloatingActionButton(
              heroTag: 'fab',
              backgroundColor: AppTheme.accentColor,
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () async {
                
                final CreatePlaylistResp dialogResp = await showDialog<CreatePlaylistResp>(
                  context: context,
                  builder: (_) => CreatePlaylistDialog()
                ) ?? const CreatePlaylistResp(isCancel: true);
      
                if( dialogResp.isCancel ) return;
      
                final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
                await onAudioQuery.createPlaylist(dialogResp.playlistName.value());
                
                showSnackbar(
                  context: context,
                  message: 'The ${ dialogResp.playlistName.value() } playlist was successfully added!'
                );
                
                musicPlayerProvider.refreshPlaylist();
              }
            ),
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
    required this.forceElevated,
  }) : super(key: key);
  final bool forceElevated;

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);

    return SliverAppBar(
      forceElevated: forceElevated,
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
              onTap: () async => await _getAllSongs(
                context: context,
                musicPlayerProvider: musicPlayerProvider,
              )
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
    showSnackbar(context: context, message: 'Task successfully completed');
  }
}