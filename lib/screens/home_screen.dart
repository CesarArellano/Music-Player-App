import 'package:flutter/material.dart';

import 'package:music_player_app/screens/albums_screens.dart';
import 'package:music_player_app/screens/songs_screen.dart';
class HomeScreen extends StatefulWidget {

  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  
  TabController? _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
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
    );
  }

  TabBar getTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const <Tab> [
        Tab(text: 'Songs'),
        Tab(text: 'Albums'),
      ] 
    );
  }

  TabBarView getTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: <Widget>[
        SongsScreen(),
        AlbumsScreen()
      ],
    );
  }

}