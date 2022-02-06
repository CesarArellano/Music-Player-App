import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/screens/screens.dart';
class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  
  TabController? _tabController;
  AnimationController? _playAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _playAnimation =  AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _playAnimation?.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _playAnimation?.dispose();
    _tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // // backgroundColor: Colors.transparent,
        // // elevation: 0.0,
        title: const Text('Music Player'),
        leading: IconButton(
          splashRadius: 22,
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
        bottom: getTabBar(),
      ),
      body: getTabBarView(),
      bottomNavigationBar: musicPlayerProvider.isLoading
      ? null
      : musicPlayerProvider.songPlayed.title.isEmpty 
        ? null
        : _CurrentSongTile(playAnimation: _playAnimation)
    );
  }

  TabBar getTabBar() {
    return TabBar(
      isScrollable: true,
      controller: _tabController,
      tabs: const <Tab> [
        Tab(text: 'Songs'),
        Tab(text: 'Albums'),
        Tab(text: 'Artists'),
        Tab(text: 'Playlists'),
        Tab(text: 'Genres'),
      ] 
    );
  }

  Widget getTabBarView() {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        const _CustomBackground(),
        TabBarView(
          controller: _tabController,
          children: const <Widget>[
            SongsScreen(),
            AlbumsScreen(),
            ArtistScreen(),
            PlaylistsScreen(),
            GenresScreen(),
          ],
        ),
      ]
    );
  }

}

class _CustomBackground extends StatelessWidget {
  const _CustomBackground({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue,
              Colors.black,
            ]
          )
        ),
      ),
    );
  }
}

class _CurrentSongTile extends StatelessWidget {
  const _CurrentSongTile({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    
    return ListTile(
      tileColor: Colors.black87,
      leading: QueryArtworkWidget(
        id: songPlayed.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.zero,
        artworkQuality: FilterQuality.high,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              final isPlaying = musicPlayerProvider.audioPlayer.isPlaying.value;
              if( isPlaying ) {
                playAnimation?.reverse();
                musicPlayerProvider.audioPlayer.pause();
              } else {
                playAnimation?.forward();
                musicPlayerProvider.audioPlayer.play();
              }
            },
            icon: AnimatedIcon( 
              progress: playAnimation!,
              icon: AnimatedIcons.play_pause,
              color: Colors.blue,
            )
          )
        ],
      ),
      title: Text(songPlayed.title, maxLines: 1, overflow: TextOverflow.ellipsis,),
      subtitle: Text(songPlayed.artist ?? 'No artist'),
      onTap: (){

      },
    );
  }
}