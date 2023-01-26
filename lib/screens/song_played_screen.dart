import 'dart:io';
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../helpers/music_actions.dart';
import '../helpers/null_extension.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../share_prefs/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork_image.dart';
import '../widgets/more_song_options_modal.dart';
import 'artist_selected_screen.dart';

class SongPlayedScreen extends StatefulWidget {
  
  const SongPlayedScreen({
    Key? key,
    this.isPlaylist = false,
    this.playlistId
  }) : super(key: key);

  final bool isPlaylist;
  final int? playlistId;

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
    
    return OrientationBuilder(
      builder: (context, orientation) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            systemNavigationBarColor: Colors.black,
          ),
          child: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: orientation == Orientation.portrait
              ? AppBar(
                centerTitle: true,
                backgroundColor: Colors.transparent,
                title: _AppBarTitle(songPlayed: songPlayed),
                leading: const _AppBarLeading(),
                actions: <Widget>[
                  _MoreOptionsModal(
                    songPlayed: songPlayed,
                    isPlaylist: widget.isPlaylist,
                    playlistId: widget.playlistId.value(),
                  ),
                ],
              )
            : null,
            body: Stack(
              children: [
                Transform.scale(
                  scale: 1.1,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: Image.file(
                          imageFile,
                          gaplessPlayback: true,
                          errorBuilder: (_, __, ___) => Image.asset('assets/images/background.jpg', gaplessPlayback: true)
                        ).image
                      )                    
                    ),
                    child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), backgroundBlendMode: BlendMode.darken),
                        ),
                      ),
                  ),
                ),
                if( orientation == Orientation.portrait )
                  _SongPlayedPortraitBody(
                    playAnimation: _playAnimation
                  ),
                if( orientation == Orientation.landscape )
                  _SongPlayedLandscapeBody(
                    playAnimation: _playAnimation,
                    isPlaylist: widget.isPlaylist,
                    playlistId: widget.playlistId.value(),
                  ),
              ]
            ),
          ),
        );
      }
    );
  }
}

class _MoreOptionsModal extends StatelessWidget {
  const _MoreOptionsModal({
    Key? key,
    required this.songPlayed,
    required this.isPlaylist,
    required this.playlistId,
  }) : super(key: key);

  final SongModel songPlayed;
  final bool isPlaylist;
  final int playlistId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 20,
      icon: const Icon(Icons.drag_indicator, color: Colors.white),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => MoreSongOptionsModal(
            song: songPlayed,
            isPlaylist: isPlaylist,
            playlistId: playlistId,
          )
        );
      },
    );
  }
}

class _AppBarLeading extends StatelessWidget {
  const _AppBarLeading({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      splashRadius: 22,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    Key? key,
    required this.songPlayed,
  }) : super(key: key);

  final SongModel songPlayed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 10,),
        const Text('PLAYING FROM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.lightTextColor, letterSpacing: 1) ),
        const SizedBox(height: 4),
        Text(songPlayed.album.valueEmpty('No Album'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1,),
      ]
    );
  }
}

class _SongPlayedPortraitBody extends StatelessWidget {
  const _SongPlayedPortraitBody({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final currentHeroId = Provider.of<UIProvider>(context).currentHeroId;
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
              Hero(
                tag: currentHeroId,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(
                    imageFile,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                    gaplessPlayback: true,
                    errorBuilder: ( _, __, ___ ) => ArtworkImage(
                      artworkId: songPlayed.id,
                      type: ArtworkType.AUDIO,
                      width: double.infinity,
                      height: 350,
                      size: 500,
                      radius: BorderRadius.circular(15),
                    )
                  ),
                ),
              ),
              SizedBox(height: size.height * 0.05),
              SizedBox(
                height: size.height * 0.08,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
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
                            child: ( songPlayed.title.value().length > 25 )
                            ? Marquee(
                              velocity: 50.0,
                              text: songPlayed.title.value(),
                              blankSpace: 30,
                              fadingEdgeEndFraction: 0.1,
                              fadingEdgeStartFraction: 0.1,
                              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                            )
                            : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 10),
                                Text( songPlayed.title.value(), style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18) ),
                                const SizedBox(height: 9)
                              ],
                            )
                          ),
                          if( songPlayed.artist.value().length > 30 )
                            const SizedBox(height: 5),
                          InkWell(
                            onTap: () {
                              final artistId = songPlayed.artistId;

                              if( artistId == null || artistId == 0) return;

                              final artistSelected = musicPlayerProvider.artistList.firstWhere((artist) => artist.id == artistId.value(), orElse: () => ArtistModel({ "_id": 0 }));
                              
                              if( artistSelected.id == 0) return;
                              
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtistSelectedScreen(artistSelected: artistSelected)
                                )
                              );
                            },
                            child: Text(
                              songPlayed.artist.valueEmpty('No Artist'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white54)
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
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
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final audioControlProvider = Provider.of<AudioControlProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton(
          heroTag: 'forward',
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          child: StreamBuilder(
            stream: audioPlayer.loopModeStream,
            builder: (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {  
              if( !snapshot.hasData ) {
                return const Icon( Icons.forward );
              }
              return Icon( ( snapshot.data == LoopMode.off ) ? Icons.forward : ( snapshot.data == LoopMode.one ) ? Icons.repeat_one :  Icons.repeat);
            },
          ),
          onPressed: () async {
            final isLoppNone = ( audioPlayer.loopMode == LoopMode.off )
              ? LoopMode.one
              : ( audioPlayer.loopMode == LoopMode.one )
                ? LoopMode.all
                : LoopMode.off;

            await audioPlayer.setLoopMode( isLoppNone );
            Fluttertoast.showToast(
              msg: ( isLoppNone == LoopMode.off ) 
                ? 'Order'
                : ( isLoppNone == LoopMode.one ) 
                  ? 'Repeat Current'
                  : 'Repeat On'
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InkWell(
              onLongPress: () {
                final secondsResult = audioControlProvider.currentDuration.inSeconds - 10;
                audioPlayer.seek( Duration(seconds: ( secondsResult >= 0) ? secondsResult : 0) );
              },
              child: FloatingActionButton(
                heroTag: 'fast_rewind',
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.fast_rewind),
                onPressed: () async {
                  await audioPlayer.seekToPrevious();
                },
                
              ),
            ),
            const SizedBox(width: 15),
            StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, snapshot) {

                final isPlaying = snapshot.data ?? false;
                
                if( isPlaying ) {
                  playAnimation?.forward();
                } else {
                  playAnimation?.reverse();
                }
                
                return FloatingActionButton(
                  heroTag: 'play_pause',
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
              onLongPress: () =>  audioPlayer.seek( Duration(seconds: audioControlProvider.currentDuration.inSeconds + 10) ),
              child: FloatingActionButton(
                heroTag: 'fast_forward',
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.fast_forward ),
                onPressed: () async {
                  await audioPlayer.seekToNext();
                },
                
              ),
            ),
          ]
        ),
        FloatingActionButton(
          heroTag: 'shuffle',
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          child: StreamBuilder(
            stream: audioPlayer.shuffleModeEnabledStream,
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if( !snapshot.hasData ) {
                return const Icon( Icons.shuffle, color: Colors.grey );
              }
            
              return Icon( Icons.shuffle, color: ( snapshot.data! ) ? Colors.white : Colors.grey );
            },
          ),
          onPressed: ()  {
            audioPlayer.setShuffleModeEnabled(!audioPlayer.shuffleModeEnabled);
            Fluttertoast.showToast(
              msg: 'Shuffle ${ ( audioPlayer.shuffleModeEnabled )  ? 'ON' : 'OFF' } ',
            );
          }
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
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
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


class _SongPlayedLandscapeBody extends StatelessWidget {
  const _SongPlayedLandscapeBody({
    Key? key,
    required this.playAnimation,
    required this.isPlaylist,
    required this.playlistId
  }) : super(key: key);

  final AnimationController? playAnimation;
  final bool isPlaylist;
  final int playlistId;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final currentHeroId = Provider.of<UIProvider>(context).currentHeroId;
    final songPlayed = musicPlayerProvider.songPlayed;
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final isFavoriteSong = musicPlayerProvider.isFavoriteSong(songPlayed.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: size.height * 0.85,
                  width: size.width * 0.38,
                  child: Hero(
                    tag: currentHeroId,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        imageFile,
                        width: double.maxFinite,
                        height: 330,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        gaplessPlayback: true,
                        errorBuilder: ( _, __, ___ ) => ArtworkImage(
                          artworkId: songPlayed.id,
                          type: ArtworkType.AUDIO,
                          width: double.infinity,
                          height: 350,
                          size: 500,
                          radius: BorderRadius.circular(15),
                        )
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _AppBarLeading(),
                            Flexible(child: _AppBarTitle(songPlayed: songPlayed)),
                            _MoreOptionsModal(
                              songPlayed: songPlayed,
                              isPlaylist: isPlaylist,
                              playlistId: playlistId
                            )
                          ],
                        ),
                        SizedBox(height: size.height * 0.33,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
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
                                    child: ( songPlayed.title.value().length > 25 )
                                    ? Marquee(
                                      velocity: 50.0,
                                      text: songPlayed.title.value(),
                                      blankSpace: 30,
                                      fadingEdgeEndFraction: 0.1,
                                      fadingEdgeStartFraction: 0.1,
                                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                                    )
                                    : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 10),
                                        Text( songPlayed.title.value(), style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18) ),
                                        const SizedBox(height: 9)
                                      ],
                                    )
                                  ),
                                  if( songPlayed.artist.value().length > 30 )
                                    const SizedBox(height: 5),
                                  InkWell(
                                    onTap: () {
                                      final artistId = songPlayed.artistId;

                                      if( artistId == null || artistId == 0) return;

                                      final artistSelected = musicPlayerProvider.artistList.firstWhere((artist) => artist.id == artistId.value(), orElse: () => ArtistModel({ "_id": 0 }));
                                      
                                      if( artistSelected.id == 0) return;
                                      
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ArtistSelectedScreen(artistSelected: artistSelected)
                                        )
                                      );
                                    },
                                    child: Text(
                                      songPlayed.artist.valueEmpty('No Artist'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white54)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => MusicActions.showCurrentPlayList(context),
                              icon: const Icon(Icons.playlist_play)
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.05),
                      const _SongTimeline(),
                      SizedBox(height: size.height * 0.09),
                      _MusicControls(playAnimation: playAnimation)
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}