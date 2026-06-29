import 'dart:io' show Platform;
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../services/snackbar_service.dart';
import '../theme/app_theme.dart';
import '../widgets/create_playlist_dialog.dart';
import '../widgets/widgets.dart';
import 'screens.dart';
import 'tabs/favorite_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _isSnackbarActive = false;
  int _selectedIndex = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(vsync: this, length: Platform.isAndroid ? 6 : 5);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = context.watch<LibraryCubit>().state;
    final playbackState = context.watch<PlaybackStateCubit>().state;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (_isSnackbarActive) {
          audioPlayerHandler<AudioPlayer>().stop();
          audioPlayerHandler<AudioPlayer>().dispose();
          SystemNavigator.pop();
        }
    
        _isSnackbarActive = true;
    
        SnackbarService.instance.showSnackbar(
          message: 'Please back again to exit',
          snackBarAction: SnackBarAction(
            label: 'EXIT',
            textColor: AppTheme.accentColor,
            onPressed: () {
              audioPlayerHandler<AudioPlayer>().stop();
              audioPlayerHandler<AudioPlayer>().dispose();
              SystemNavigator.pop();
            },
          ),
        ).closed.then((_) => _isSnackbarActive = false);
      },
      child: Scaffold(
        appBar: _CustomAppBar(tabController: _tabController),
        body: TabBarView(
          controller: _tabController,
          children: <Widget>[
            const SongsScreen(),
            const AlbumsScreen(),
            const ArtistScreen(),
            if (Platform.isAndroid) const PlaylistsScreen(),
            const FavoriteScreen(),
            const GenresScreen(),
          ],
        ),
        floatingActionButton: libraryState.songList.isEmpty
            ? null
            : FloatingActionButton(
                heroTag: 'fab',
                backgroundColor: AppTheme.accentColor,
                onPressed: libraryState.isCreatingArtworks
                    ? null
                    : _selectedIndex == 3
                        ? () => _addPlaylist()
                        : () => _shuffleAction(libraryState),
                child: libraryState.isCreatingArtworks
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Icon(
                        _selectedIndex == 3 ? Icons.add : Icons.shuffle,
                        color: Colors.black,
                      ),
              ),
        bottomNavigationBar:
            (libraryState.isLoading || playbackState.songPlayed.id == 0)
                ? null
                : const CurrentSongTile(),
      ),
    );
  }

  Future<void> _addPlaylist() async {
    final libraryCubit = context.read<LibraryCubit>();
    final CreatePlaylistResp dialogResp =
        await showDialog<CreatePlaylistResp>(
              context: context,
              builder: (_) => CreatePlaylistDialog(),
            ) ??
            const CreatePlaylistResp(isCancel: true);

    if (dialogResp.isCancel) return;

    final onAudioQuery = audioPlayerHandler<MusicQuerySelector>();
    final playlistName = dialogResp.playlistName.value();
    await onAudioQuery.createPlaylist(playlistName);

    if (!mounted) return;

    SnackbarService.instance.showSnackbar(
      message: 'The $playlistName playlist was successfully added!',
    );

    libraryCubit.refreshPlaylist();
  }

  void _shuffleAction(LibraryState libraryState) {
    final index = Random().nextInt(libraryState.songList.length);
    final song = libraryState.songList[index];
    MusicActions.songPlayAndPause(
      context,
      song,
      PlaylistType.songs,
      heroId: 'songs-${song.id}',
      activateShuffle: true,
    );
  }

  void _handleTabSelection() {
    setState(() {
      _selectedIndex = _tabController.index;
    });
  }
}

class _CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _CustomAppBar({required this.tabController});

  final TabController tabController;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final libraryCubit = context.read<LibraryCubit>();

    return AppBar(
      backgroundColor: AppTheme.backgroundBase,
      title: const Text('Focus Music Player'),
      shape: const Border(bottom: BorderSide(color: Colors.white24)),
      bottom: TabBar(
        controller: tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AppTheme.accentColor,
        labelColor: Colors.white,
        labelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        unselectedLabelColor: AppTheme.lightTextColor,
        indicatorWeight: 3.0,
        tabs: <Widget>[
          const Tab(text: 'Songs'),
          const Tab(text: 'Albums'),
          const Tab(text: 'Artists'),
          if (Platform.isAndroid) const Tab(text: 'Playlist'),
          const Tab(text: 'Favorites'),
          const Tab(text: 'Genres'),
        ],
      ),
      actions: <Widget>[
        IconButton(
          splashRadius: 20,
          icon: const Icon(Icons.search),
          color: AppTheme.lightTextColor,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MusicSearchScreen()),
          ),
          tooltip: 'Search music',
        ),
        PopupMenuButton(
          color: Colors.white,
          icon: const Icon(Icons.more_vert, color: AppTheme.lightTextColor),
          tooltip: 'More options',
          itemBuilder: (_) => [
            PopupMenuItem(
              child: const Text('Share App',
                  style: TextStyle(color: Colors.black)),
              onTap: () async {
                await SharePlus.instance.share(ShareParams(
                  text:
                      "Hey, I Recommend this App fopr you. It's Most Stylish MP3 Music Player for your Android Device You would definitely like it.Please Try it Out. https://github.com/CesarArellano/Music-Player-App",
                ));
              },
            ),
            PopupMenuItem(
              child: const Text('Scan media',
                  style: TextStyle(color: Colors.black)),
              onTap: () async {
                await libraryCubit.getAllSongs();
                SnackbarService.instance.showSnackbar(message: 'Task successfully completed');
              },
            ),
          ],
        ),
      ],
    );
  }
}
