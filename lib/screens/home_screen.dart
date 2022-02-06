import 'package:flutter/material.dart';
import 'package:music_player_app/search/search_delegate.dart';
import 'package:provider/provider.dart';

import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/screens/screens.dart';
import '../widgets/widgets.dart';

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
        elevation: 0.0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF003A7C),
                Color(0xCC174A85)
              ]
            ),
        )
        ),
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
            onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
          ),
        ],
        bottom: getTabBar(),
      ),
      body: getTabBarView(),
      bottomNavigationBar: musicPlayerProvider.isLoading
      ? null
      : musicPlayerProvider.songPlayed.title.isEmpty 
        ? null
        : CurrentSongTile(playAnimation: _playAnimation)
    );
  }

  TabBar getTabBar() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w400),
      tabs: const <Tab> [
        Tab(text: 'SONGS'),
        Tab(text: 'ALBUMS'),
        Tab(text: 'ARTISTS'),
        Tab(text: 'PLAYLISTS'),
        Tab(text: 'GENRES'),
      ] 
    );
  }

  Widget getTabBarView() {
    return Stack(
      children: [
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
      ],
    );
  }

}

class _CustomBackground extends StatelessWidget {
  const _CustomBackground({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(23, 74, 133, 1),
            Color.fromARGB(255, 15, 51, 92),
          ]
        )
      ),
    );
  }
}