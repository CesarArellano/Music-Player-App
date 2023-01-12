import 'dart:io';
import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:music_player_app/theme/app_theme.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../helpers/music_actions.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../share_prefs/user_preferences.dart';
import '../widgets/artwork_image.dart';
import '../widgets/more_song_options_modal.dart';

class SongPlayedScreen extends StatefulWidget {
  
  const SongPlayedScreen({Key? key}) : super(key: key);

  @override
  State<SongPlayedScreen> createState() => _SongPlayedScreenState();
}

class _SongPlayedScreenState extends State<SongPlayedScreen> with SingleTickerProviderStateMixin {
  AnimationController? _playAnimation;

  @override
  void initState() {
    super.initState();
    _playAnimation =  AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _playAnimation?.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _playAnimation?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
      
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          title: Column(
            children: [
              const SizedBox(height: 10,),
              const Text('PLAYING FROM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor, letterSpacing: 1) ),
              const SizedBox(height: 4),
              Text(songPlayed.album ?? 'No Album', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            ]
          ),
          leading: IconButton(
            splashRadius: 22,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: <Widget>[
            IconButton(
              splashRadius: 20,
              icon: const Icon(Icons.drag_indicator, color: Colors.white),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder:(context) => MoreSongOptionsModal(song: songPlayed)
                );
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 400),
              child: Transform.scale(
                scale: 1.1,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: imageFile.existsSync()
                      ? Image.file(
                          imageFile,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/background.jpg', gaplessPlayback: true)
                        ).image
                      : const AssetImage('assets/images/background.jpg')
                    )                    
                  ),
                  child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), backgroundBlendMode: BlendMode.darken),
                      ),
                    ),
                ),
              )
            ),
            _SongPlayedBody( playAnimation: _playAnimation ),
          ]
        ),
      ),
    );
  }
}

class _SongPlayedBody extends StatelessWidget {
  const _SongPlayedBody({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final isFavoriteSong = musicPlayerProvider.isFavoriteSong(songPlayed.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.015),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.file(
                  imageFile,
                  width: double.infinity,
                  height: 350,
                  gaplessPlayback: true,
                  errorBuilder: (_,__,___) => ArtworkImage(
                    artworkId: songPlayed.id,
                    type: ArtworkType.AUDIO,
                    width: double.infinity,
                    height: 350,
                    size: 500,
                    radius: BorderRadius.circular(6),
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.05),
              SizedBox(
                height: size.height * 0.07,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        List<String> favoriteSongList = [ ...musicPlayerProvider.favoriteSongList ];
                        List<SongModel> favoriteList = [ ...musicPlayerProvider.favoriteList ];

                        if( isFavoriteSong ) {
                          favoriteList.removeWhere(((song) => song.id == songPlayed.id));
                          favoriteSongList.removeWhere(((songId) => songId == songPlayed.id.toString()));
                        } else {
                          final index = musicPlayerProvider.songList.indexWhere((song) => song.id == songPlayed.id);
                          favoriteList.add( musicPlayerProvider.songList[index] );
                          favoriteSongList.add(songPlayed.id.toString());
                        }

                        musicPlayerProvider.favoriteList = favoriteList;
                        musicPlayerProvider.favoriteSongList = favoriteSongList;
                        UserPreferences().favoriteSongList = favoriteSongList;
                      },
                      icon: Icon( isFavoriteSong ? Icons.favorite : Icons.favorite_border)
                    ),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible (
                            child: ( (songPlayed.title ?? '').length > 25 )
                            ? Marquee(
                              velocity: 50.0,
                              text: songPlayed.title ?? '',
                              blankSpace: 30,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            )
                            : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                Text( songPlayed.title ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18) ),
                                const SizedBox(height: 9)
                              ],
                            )
                          ),
                          if( (songPlayed.artist ?? '').length > 30 )
                            const SizedBox(height: 10,),
                          Text(
                            songPlayed.artist ?? 'No Artist',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white54)
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => MusicActions.showCurrentPlayList(context),
                      icon: const Icon(Icons.playlist_play)
                    )
                  ],
                ),
              ),
              SizedBox(height: size.height * 0.1),
              const _SongTimeline(),
              SizedBox(height: size.height * 0.09),
              _MusicControls(playAnimation: playAnimation)
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicControls extends StatelessWidget {
  const _MusicControls({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final controlProvider = Provider.of<AudioControlProvider>(context, listen: false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton(
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          child: StreamBuilder(
            stream: audioPlayer.loopMode,
            builder: (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {  
              if( !snapshot.hasData ) {
                return const Icon( Icons.forward );
              }
              return Icon( ( snapshot.data == LoopMode.none ) ? Icons.forward : Icons.repeat_one );
            },
          ),
          onPressed: () async {
            await audioPlayer.setLoopMode( 
              audioPlayer.currentLoopMode == LoopMode.none
              ? LoopMode.single
              : LoopMode.none
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onLongPress: () =>  audioPlayer.seekBy( const Duration(seconds: -10) ),
              child: FloatingActionButton(
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.fast_rewind),
                onPressed: () {
                  if( audioPlayer.currentLoopMode == LoopMode.none && controlProvider.currentIndex > 0 ) {
                    controlProvider.currentIndex -= 1;
                    musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[controlProvider.currentIndex];
                    audioPlayer.previous();
                  }
                },
                
              ),
            ),
            const SizedBox(width: 15),
            StreamBuilder<bool>(
              stream: audioPlayer.isPlaying,
              builder: (context, snapshot) {

                final isPlaying = snapshot.data ?? false;
                
                if( isPlaying ) {
                  playAnimation?.forward();
                } else {
                  playAnimation?.reverse();
                }
                
                return FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () {
                    if( isPlaying ) {
                      playAnimation?.reverse();
                      audioPlayer.pause();
                    } else {
                      playAnimation?.forward();
                      audioPlayer.play();
                    }
                  },
                  child: AnimatedIcon( 
                    progress: playAnimation!,
                    icon: AnimatedIcons.play_pause,
                    color: Colors.black,
                  )
                );
              }
            ),
            const SizedBox(width: 15),
            InkWell(
              onLongPress: () =>  audioPlayer.seekBy( const Duration(seconds: 10) ),
              child: FloatingActionButton(
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.fast_forward ),
                onPressed: () {
                  if( audioPlayer.currentLoopMode == LoopMode.none && controlProvider.currentIndex <= musicPlayerProvider.currentPlaylist.length - 2 ) {
                    controlProvider.currentIndex += 1;
                    musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[controlProvider.currentIndex];
                    audioPlayer.next();
                  }
                },
                
              ),
            ),
          ]
        ),
        FloatingActionButton(
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          child: StreamBuilder(
            stream: audioPlayer.isShuffling,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if( !snapshot.hasData ) {
                return const Icon( Icons.shuffle, color: Colors.grey );
              }
            
              return Icon( Icons.shuffle, color: ( snapshot.data! ) ? Colors.white : Colors.grey );
            },
          ),
          onPressed: () {
            // musicPlayerProvider.audioPlayer.toggleShuffle();
            // musicPlayerProvider.currentPlaylist = [];

            // List<SongModel> tempList = [];

            // for( var song in musicPlayerProvider.audioPlayer.playlist!.audios ) {
            //   final index = musicPlayerProvider.songList.indexWhere((songStored) => songStored.data == song.path );
            //   tempList.add( musicPlayerProvider.songList[index] );
            // }

            // musicPlayerProvider.currentPlaylist = tempList;
            // final currentIndex = musicPlayerProvider.currentPlaylist.indexWhere((songStored) => songStored.data ==  musicPlayerProvider.audioPlayer.current.value!.audio.assetAudioPath);
            // controlProvider.currentIndex = currentIndex;
            // musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[currentIndex];
            // print( musicPlayerProvider.songPlayed.title);
          },
        ),
      ],
    );
  }
}

class _SongTimeline extends StatelessWidget {
  const _SongTimeline({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AssetsAudioPlayer>();
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final songPlayed = musicPlayerProvider.songPlayed;

    return ProgressBar(
      thumbGlowRadius: 15.0,
      thumbRadius: 8.0,
      barHeight: 3.0,
      progressBarColor: Colors.white,
      thumbColor: Colors.white,
      progress: audioControlProvider.currentDuration,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: (duration) {
        audioPlayer.seek(duration);
      },
      timeLabelTextStyle: const TextStyle(color: AppTheme.lightTextColor, fontWeight: FontWeight.w500),
    );
  }
}