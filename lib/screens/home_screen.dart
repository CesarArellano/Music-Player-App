import 'dart:io' show Platform;
import 'dart:math' show Random;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../extensions/extensions.dart';
import '../helpers/helpers.dart';
import '../helpers/music_actions.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isSnackbarActive = false;
  int _selectedIndex = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: Platform.isAndroid ? 6 : 5);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabController.removeListener(_handleTabSelection);
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = context.watch<MusicPlayerProvider>();
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _CustomAppBar(tabController: _tabController),
        body: _Body(tabController: _tabController),
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab',
          backgroundColor: AppTheme.accentColor,
          onPressed: musicPlayerProvider.isCreatingArtworks
              ? null
              : _selectedIndex == 3
                ? () => _addPlaylist(musicPlayerProvider) 
                : () => _shuffleAction(musicPlayerProvider),
          child: musicPlayerProvider.isCreatingArtworks 
              ? const CircularProgressIndicator(color: Colors.black,)
              : Icon( _selectedIndex == 3 ? Icons.add : Icons.shuffle, color: Colors.black)
        ),
        bottomNavigationBar: (musicPlayerProvider.isLoading || ( musicPlayerProvider.songPlayed.title.value() ).isEmpty)
          ? null
          : const CurrentSongTile()
      ),
    );
  }

  Future<void> _addPlaylist(MusicPlayerProvider musicPlayerProvider) async {
    final CreatePlaylistResp dialogResp = await showDialog<CreatePlaylistResp>(
      context: context,
      builder: (_) => CreatePlaylistDialog()
    ) ?? const CreatePlaylistResp(isCancel: true);

    if( dialogResp.isCancel ) return;

    final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
    await onAudioQuery.createPlaylist(dialogResp.playlistName.value());
    
    if( !mounted ) return;

    Helpers.showSnackbar(
      message: 'The ${ dialogResp.playlistName.value() } playlist was successfully added!'
    );
    
    musicPlayerProvider.refreshPlaylist();
  }

  void _shuffleAction(MusicPlayerProvider musicPlayerProvider) {
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

  void _handleTabSelection() {
    setState(() { 
      _selectedIndex = _tabController.index;
    });
  }

  Future<bool> _onWillPop() async {
    if( _isSnackbarActive ) {
      audioPlayerHandler<AudioPlayer>().stop();
      audioPlayerHandler<AudioPlayer>().dispose();
      SystemNavigator.pop();
      return true;
    }

    _isSnackbarActive = true;
    
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
    ).closed.then((_) => _isSnackbarActive = false);

    await Future.delayed(const Duration(seconds: 4));
    return false;
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
    required this.tabController
  }): super(key: key);

  final TabController tabController;

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 50),
          child: Container(
            color: AppTheme.primaryColor.withOpacity(0.8),
          ),
        ),
        ),
        
        TabBarView(
          controller: tabController,
          children: const <Widget>[
            SongsScreen(),
            AlbumsScreen(),
            ArtistScreen(),
            PlaylistsScreen(),
            FavoriteScreen(),
            GenresScreen(),
          ],
        ),
      ],
    );
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar({
    Key? key,
    required this.tabController
  }) : super(key: key);

  final TabController tabController;

  @override
  Widget build(BuildContext context) {

    return AppBar(
      title: const Text('Focus Music Player'),
      shape: const Border(bottom: BorderSide(color: Colors.white24)),
      bottom: TabBar(
        controller: tabController,
        isScrollable: true,
        indicatorColor: AppTheme.accentColor,
        labelColor: Colors.white,
        labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelColor: AppTheme.lightTextColor,
        indicatorWeight: 3.0,
        tabs: const <Widget> [
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
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 1.75);
}

