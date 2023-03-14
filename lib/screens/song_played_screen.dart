import 'dart:io' show File;
import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:focus_music_player/screens/album_selected_screen.dart';
import 'package:focus_music_player/theme/app_theme.dart';
import 'package:focus_music_player/widgets/bouncing_widget.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../helpers/music_actions.dart';
import '../extensions/extensions.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../providers/ui_provider.dart';
import '../share_prefs/user_preferences.dart';
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
  late AnimationController _playAnimation;

  @override
  void initState() {
    super.initState();
    _playAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _playAnimation.forward();
  }

  @override
  void dispose() {
    super.dispose();
    _playAnimation.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;
    final imageFile = File('${ musicPlayerProvider.appDirectory }/${ songPlayed.albumId }.jpg');
    final uiProvider = Provider.of<UIProvider>(context);
    final songPlayedBrightness = uiProvider.songPlayedBrightness;
    final songPlayedThemeColor = uiProvider.songPlayedThemeColor;

    return OrientationBuilder(
      builder: (context, orientation) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.black,
            statusBarIconBrightness: songPlayedBrightness,
          ),
          child: Theme(
            data: AppTheme.lightTheme.copyWith(
              textTheme: uiProvider.songPlayedTypography,
              colorScheme: ColorScheme.dark(
                primary: songPlayedThemeColor,
                onSurface: songPlayedThemeColor,
              ),
              iconButtonTheme: IconButtonThemeData(
                style: ButtonStyle(iconColor: MaterialStatePropertyAll(songPlayedThemeColor))
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                foregroundColor: songPlayedThemeColor,
              )
            ),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: orientation == Orientation.portrait
                ? AppBar(
                  centerTitle: true,
                  backgroundColor: Colors.transparent,
                  title: _AppBarTitle(songPlayed: songPlayed),
                  systemOverlayStyle: SystemUiOverlayStyle(
                    statusBarIconBrightness: songPlayedBrightness
                  ),
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
                  FadeIn(
                    duration: const Duration(milliseconds: 300),
                    child: Transform.scale(
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
                              decoration: BoxDecoration(color: uiProvider.currentDominantColor.withOpacity(0.7)),
                            ),
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
      icon: const Icon(Icons.more_vert),
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final albumSelected = musicPlayerProvider.albumList.firstWhere((album) => album.id == songPlayed.albumId.value(), orElse: () => AlbumModel({ "_id": 0 }));

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 10,),
        const Text('PLAYING FROM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 1) ),
        const SizedBox(height: 4),
        InkWell(
          child: Text(
            songPlayed.album.valueEmpty('No Album'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: ( _ ) => AlbumSelectedScreen(albumSelected: albumSelected))),
        ),
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
        child: Column(
          children: [
            const SizedBox(height: 10),
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
            const SizedBox(height: 40),
            SizedBox(
              height: size.height * 0.075,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CustomIconButton(
                    icon: isFavoriteSong ? Icons.favorite : Icons.favorite_border,
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
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible (
                          child: ( songPlayed.title.value().length > 25 )
                          ? SizedBox(
                            height: 40,
                            child: Marquee(
                              velocity: 45.0,
                              text: songPlayed.title.value(),
                              blankSpace: 20,
                              fadingEdgeEndFraction: 0.1,
                              fadingEdgeStartFraction: 0.1,
                              style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                              textScaleFactor: 1,
                            ),
                          )
                          : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                songPlayed.title.value(),
                                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
                              ),
                              const SizedBox(height: 9)
                            ],
                          )
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              final artistId = songPlayed.artistId;
                        
                              if( artistId == null || artistId == 0) return;
                        
                              final artistSelected = musicPlayerProvider.artistList.firstWhere((artist) => artist.id == artistId.value(), orElse: () => ArtistModel({ "_id": 0 }));
                              
                              if( artistSelected.id == 0) return;
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtistSelectedScreen(artistSelected: artistSelected)
                                )
                              );
                            },
                            child: Text(
                              songPlayed.artist.valueEmpty('No Artist'),
                              textScaleFactor: 1,
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                              ).copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                  _CustomIconButton(
                    icon: Icons.playlist_play_rounded,
                    onPressed: () => MusicActions.showCurrentPlayList(context),
                  )
                ],
              ),
            ),
            const Spacer(),
            const _SongTimeline(),
            const Spacer(),
            _MusicControls(playAnimation: playAnimation),
            const SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}

class _CustomIconButton extends StatelessWidget {
  const _CustomIconButton({
    Key? key,
    required this.icon,
    this.onPressed
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final songPlayedThemeColor = Provider.of<UIProvider>(context).songPlayedThemeColor;

    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, color: songPlayedThemeColor),
    );
  }
}

class _MusicControls extends StatefulWidget {
  const _MusicControls({
    Key? key,
    required this.playAnimation,
  }) : super(key: key);

  final AnimationController? playAnimation;

  @override
  State<_MusicControls> createState() => _MusicControlsState();
}

class _MusicControlsState extends State<_MusicControls> {
  
  bool _buttonPressed = false;
  bool _loopActive = false;

  @override
  Widget build(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final audioControlProvider = Provider.of<AudioControlProvider>(context, listen: false);
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

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
              return Icon( ( snapshot.data == LoopMode.off ) ? Icons.repeat : ( snapshot.data == LoopMode.one ) ? Icons.repeat_one :  Icons.keyboard_double_arrow_right);
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
            Listener(
              onPointerDown: (_) {
                setState(() => _buttonPressed = true);
                _whilePressed(
                  audioControlProvider: audioControlProvider,
                  audioPlayer: audioPlayer,
                  currentIndex: audioControlProvider.currentIndex,
                  songDurationSeconds: Duration(milliseconds: musicPlayerProvider.songPlayed.duration.value() ).inSeconds,
                  goToSeconds: -10
                );
              },
              onPointerUp: (_) => setState(() => _buttonPressed = false),
              child: FloatingActionButton(
                heroTag: 'fast_rewind',
                elevation: 0.0,
                highlightElevation: 0.0,
                splashColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.skip_previous),
                onPressed: () async {
                  setState(() => _buttonPressed = false);
                  await audioPlayer.seekToPrevious();
                },
                
              ),
            ),
            const SizedBox(width: 15),
            StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, snapshot) {

                final isPlaying = snapshot.data ?? audioPlayer.playing;
                
                if( isPlaying ) {
                  widget.playAnimation?.forward();
                } else {
                  widget.playAnimation?.reverse();
                }
                
                return Bouncing(
                  child: FloatingActionButton(
                    heroTag: 'play_pause',
                    shape: isPlaying ? null : const CircleBorder(),
                    onPressed: () {
                      if( isPlaying ) {
                        widget.playAnimation?.reverse();
                        audioPlayer.pause();
                      } else {
                        widget.playAnimation?.forward();
                        audioPlayer.play();
                      }
                    },
                    child: AnimatedIcon( 
                      progress: widget.playAnimation!,
                      icon: AnimatedIcons.play_pause,
                      color: onSurfaceColor == Colors.white ? Colors.black : Colors.white,
                    )
                  ),
                );
              }
            ),
            const SizedBox(width: 15),
            Listener(
              onPointerDown: (_) {
                setState(() => _buttonPressed = true);
                _whilePressed(
                  audioControlProvider: audioControlProvider,
                  audioPlayer: audioPlayer,
                  currentIndex: audioControlProvider.currentIndex,
                  songDurationSeconds: Duration(milliseconds: musicPlayerProvider.songPlayed.duration.value() ).inSeconds,
                  goToSeconds: 10
                );
              },
              onPointerUp: (_) => setState(() => _buttonPressed = false),
              child: FloatingActionButton(
                heroTag: 'fast_forward',
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                child: const Icon( Icons.skip_next_sharp ),
                onPressed: () async {
                  setState(() => _buttonPressed = false);
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
                return Icon( Icons.shuffle, color: onSurfaceColor.withOpacity(0.6));
              }
            
              return Icon( Icons.shuffle, color: ( snapshot.data! ) ?  onSurfaceColor : onSurfaceColor.withOpacity(0.6));
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

  void _whilePressed({
    required AudioControlProvider audioControlProvider,
    required AudioPlayer audioPlayer,
    required int currentIndex,
    required int songDurationSeconds,
    required int goToSeconds
  }) async {
    
    if (_loopActive) return;// check if loop is active

    _loopActive = true;

    while (_buttonPressed) {

      final secondsResult = audioControlProvider.currentDuration.inSeconds + goToSeconds;

      if( currentIndex != audioPlayer.currentIndex ) {
        _buttonPressed = false;
        break;
      }
      if( secondsResult <= 0 ) {
        _buttonPressed = false;
      }
      audioPlayer.seek( Duration(seconds: ( secondsResult >= 0) ? secondsResult : 0) );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _loopActive = false;
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
      progress: audioControlProvider.currentDuration,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: (duration) {
        audioPlayer.seek(duration);
      },
      timeLabelTextStyle: const TextStyle(fontWeight: FontWeight.w500)
        .copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                      SizedBox(
                        height: size.height * 0.34,
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
                                    textScaleFactor: 1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16)
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
                    const Spacer(),
                    const _SongTimeline(),
                    const Spacer(),
                    _MusicControls(playAnimation: playAnimation),
                    const SizedBox(height: 15),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}