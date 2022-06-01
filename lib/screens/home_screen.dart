import 'package:flutter/material.dart';
import 'package:music_player_app/audio_player_handler.dart';
import 'package:music_player_app/helpers/custom_snackbar.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../providers/music_player_provider.dart';
import '../search/search_delegate.dart';
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
                title: const Text('Escriba el nombre de la playlist'),
                content: Form(
                  key: _keyForm,
                  child: TextFormField(
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
                actions: [
                  TextButton(
                    child: const Text('Cerrar'),
                    onPressed:() {
                      Navigator.pop(context, false);
                    } , 
                  ),
                  TextButton(
                    child: const Text('Crear'),
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
            final createPlaylistResp = await onAudioQuery.createPlaylist(namePlaylist);
            if( createPlaylistResp ) {
              showSnackbar(
                context: context,
                message: '¡La playlist $namePlaylist fue agregada con éxito!'
              );
              musicPlayerProvider.refreshPlaylist();
            }
          }
        ),
        bottomNavigationBar: (musicPlayerProvider.isLoading || musicPlayerProvider.songPlayed.title.isEmpty)
          ? null
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