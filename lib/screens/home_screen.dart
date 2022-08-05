import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_player_handler.dart';
import '../helpers/custom_snackbar.dart';
import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'screens.dart';

class HomeScreen extends StatelessWidget {
  
  HomeScreen({Key? key}) : super(key: key);

  final GlobalKey<FormState> _keyForm = GlobalKey<FormState>();
  final TextEditingController _namePlaylistCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Focus Music Player'),
          actions: <Widget>[
            IconButton(
              splashRadius: 20,
              icon: const Icon(Icons.search),
              onPressed: () => showSearch(context: context, delegate: MusicSearchDelegate() ),
              tooltip: 'Search music',
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: const Text('Share App', style: TextStyle(color: Colors.black)),
                  onTap: () async {
                    await Share.share("Hey, I Recommend this App fopr you. It's Most Stylish MP3 Music Player for your Android Device You would definitely like it.Please Try it Out. https://github.com/CesarArellano/Music-Player-App");
                  },
                )
              ],
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white,
            tabs: <Tab> [
              Tab(text: 'SONGS'),
              Tab(text: 'ALBUMS'),
              Tab(text: 'ARTISTS'),
              Tab(text: 'PLAYLISTS'),
              Tab(text: 'GENRES'),
            ],
          )
        ),
        body: getTabBarView(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.add, color: Colors.black),
          onPressed: () async {
            String namePlaylist = '';
            final bool dialogResp = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: AppTheme.primaryColor,
                title: const Text('New playlist...'),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Form(
                    key: _keyForm,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Playlist name',
                        hintStyle: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.w400 )
                      ),
                      controller: _namePlaylistCtrl,
                      onSaved: (value) {
                        namePlaylist = (value ?? '').trim();
                      },
                      validator: (value) {
                        if( value == null || value.isEmpty ){
                          return 'Ingrese un nombre';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    child: const Text('CANCEL'),
                    onPressed:() {
                      Navigator.pop(context, false);
                    } , 
                  ),
                  TextButton(
                    child: const Text('CREATE'),
                    onPressed:() {
                      if( !_keyForm.currentState!.validate() ) return;
                      _keyForm.currentState!.save();
                      Navigator.pop(context, true);
                    } , 
                  ),
                ],
              )
            ) ?? false;

            if( !dialogResp ) return;

            final onAudioQuery = audioPlayerHandler<OnAudioQuery>();
            await onAudioQuery.createPlaylist(namePlaylist);
            showSnackbar(
              context: context,
              message: '¡La playlist $namePlaylist fue agregada con éxito!'
            );
            musicPlayerProvider.refreshPlaylist();
          }
        ),
        bottomNavigationBar: (musicPlayerProvider.isLoading || musicPlayerProvider.songPlayed.title.isEmpty)
          ? const CustomBottomNavigationBar()
          : const CurrentSongTile()
      ),
    );
  }

  Widget getTabBarView() {
    return Stack(
      children: const [
        CustomBackground(),
        TabBarView(
          children: <Widget>[
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