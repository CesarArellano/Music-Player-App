import 'dart:async';
import 'dart:io' show File;
import 'dart:ui';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marqueer/marqueer.dart';
import 'package:music_query_selector/music_query_selector.dart';
import 'package:volume_controller/volume_controller.dart';

import '../audio_player_handler.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../helpers/music_actions.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/bouncing_widget.dart';
import '../widgets/widgets.dart';
import 'album_selected_screen.dart';
import 'artist_selected_screen.dart';

class SongPlayedScreen extends StatefulWidget {
  const SongPlayedScreen({
    super.key,
    this.isPlaylist = false,
    this.playlistId,
  });

  final bool isPlaylist;
  final int? playlistId;

  @override
  State<SongPlayedScreen> createState() => _SongPlayedScreenState();
}

class _SongPlayedScreenState extends State<SongPlayedScreen>
    with SingleTickerProviderStateMixin {
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
    _playAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = context.watch<PlaybackStateCubit>().state;
    final favoritesState = context.watch<FavoritesCubit>().state;
    final libraryState = context.watch<LibraryCubit>().state;
    final uiState = context.watch<UICubit>().state;
    final songPlayed = playbackState.songPlayed;
    final imageFile =
        File('${libraryState.appDirectory}/${songPlayed.albumId}.jpg');
    final songPlayedBrightness = uiState.songPlayedBrightness;
    final songPlayedThemeColor = uiState.songPlayedThemeColor;

    return OrientationBuilder(
      builder: (context, orientation) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarIconBrightness: songPlayedBrightness,
            systemNavigationBarColor: uiState.dominantColor
          ),
          child: Theme(
            data: AppTheme.darkTheme.copyWith(
              textTheme: uiState.songPlayedTypography,
              colorScheme: ColorScheme.dark(
                primary: songPlayedThemeColor,
                onSurface: songPlayedThemeColor,
              ),
              iconButtonTheme: IconButtonThemeData(
                style: ButtonStyle(
                  iconColor: WidgetStatePropertyAll(songPlayedThemeColor),
                ),
              ),
              appBarTheme: AppBarTheme(
                iconTheme: IconThemeData(color: songPlayedThemeColor),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                foregroundColor: songPlayedThemeColor,
              ),
            ),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: orientation == Orientation.portrait
                  ? AppBar(
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      title: _AppBarTitle(songPlayed: songPlayed),
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarIconBrightness: songPlayedBrightness,
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
                  const AppBackground(),
                  Transform.scale(
                    scale: 1.1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageFile.existsSync())
                          // ImageFiltered blurs this image (its child) directly.
                          // Unlike BackdropFilter it never samples the route
                          // behind it, so the home screen isn't blurred during
                          // the open/close slide transition.
                          ImageFiltered(
                            imageFilter:
                                ImageFilter.blur(sigmaX: 50.0, sigmaY: 50.0),
                            child: Image.file(
                              imageFile,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.low,
                              cacheWidth: 200,
                              errorBuilder: (_, _, _) => const SizedBox.shrink(),
                            ),
                          ),
                        Container(
                          color: uiState.dominantColor.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                  ),
                  if (orientation == Orientation.portrait)
                    _SongPlayedPortraitBody(
                      playAnimation: _playAnimation,
                      songPlayed: songPlayed,
                      imageFile: imageFile,
                      isFavoriteSong: favoritesState.isFavoriteSong(songPlayed.id),
                      currentHeroId: uiState.currentHeroId,
                      playbackState: playbackState,
                      libraryState: libraryState,
                    ),
                  if (orientation == Orientation.landscape)
                    _SongPlayedLandscapeBody(
                      playAnimation: _playAnimation,
                      isPlaylist: widget.isPlaylist,
                      playlistId: widget.playlistId.value(),
                      songPlayed: songPlayed,
                      imageFile: imageFile,
                      isFavoriteSong: favoritesState.isFavoriteSong(songPlayed.id),
                      currentHeroId: uiState.currentHeroId,
                      playbackState: playbackState,
                      libraryState: libraryState,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MoreOptionsModal extends StatelessWidget {
  const _MoreOptionsModal({
    required this.songPlayed,
    required this.isPlaylist,
    required this.playlistId,
  });

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
          ),
        );
      },
    );
  }
}

class _AppBarLeading extends StatelessWidget {
  const _AppBarLeading();

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
  const _AppBarTitle({required this.songPlayed});

  final SongModel songPlayed;

  @override
  Widget build(BuildContext context) {
    final albumList =
        context.select((LibraryCubit c) => c.state.albumList);
    final albumSelected = albumList.firstWhere(
      (album) => album.id == songPlayed.albumId.value(),
      orElse: () => AlbumModel({'_id': 0}),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          'PLAYING FROM',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          child: Text(
            songPlayed.album.valueEmpty('No Album'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 1,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AlbumSelectedScreen(albumSelected: albumSelected),
            ),
          ),
        ),
      ],
    );
  }
}

/// Swipeable artwork: each page is a song in the current queue. Swiping seeks
/// the player to that song; external song changes (next/prev, auto-advance)
/// animate the carousel back in sync.
class _ArtworkCarousel extends StatefulWidget {
  const _ArtworkCarousel({
    required this.currentHeroId,
    required this.height,
  });

  final String currentHeroId;
  final double height;

  @override
  State<_ArtworkCarousel> createState() => _ArtworkCarouselState();
}

class _ArtworkCarouselState extends State<_ArtworkCarousel> {
  late final PageController _controller;
  late int _activeIndex;

  // True while the user is dragging the carousel (so external sync won't fight
  // them). [_userSwipe] latches a *user-initiated* page change so that
  // programmatic animateToPage (external song changes / transient index emits
  // from the player) never trigger a seek — that was causing the wrong song.
  bool _isUserDragging = false;
  bool _userSwipe = false;
  double _volume = 0.5;
  bool _showVolumeSlider = false;
  bool _isVolumeDragging = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _activeIndex = context.read<AudioControlCubit>().state.currentIndex;
    _controller = PageController(initialPage: _activeIndex);
    VolumeController.instance.showSystemUI = false;
    VolumeController.instance.addListener(
      (v) { if (mounted && !_isVolumeDragging) setState(() => _volume = v); },
      fetchInitialVolume: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    VolumeController.instance.removeListener();
    VolumeController.instance.showSystemUI = true;
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    _activeIndex = index;

    // Only a real swipe seeks. Programmatic moves leave [_userSwipe] false.
    if (!_userSwipe) return;
    _userSwipe = false;

    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    if (index == audioPlayer.currentIndex) return;
    audioPlayer.seek(Duration.zero, index: index);
    audioPlayer.play();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final delta = -details.delta.dy / widget.height;
    final newVol = (_volume + delta).clamp(0.0, 1.0);
    VolumeController.instance.setVolume(newVol);
    setState(() {
      _volume = newVol;
      _showVolumeSlider = true;
    });
  }

  void _restartHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showVolumeSlider = false);
    });
  }

  Widget _buildVolumeOverlay() {
    final IconData icon = _volume == 0
        ? Icons.volume_off_rounded
        : _volume < 0.35
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

    return Center(
      child: Container(
        width: 52,
        height: widget.height * 0.55,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            Text(
              '${(_volume * 100).round()}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RotatedBox(
                quarterTurns: 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _volume,
                    backgroundColor: Colors.black38,
                    color: Colors.black,
                    minHeight: 6,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: Colors.black, size: 22),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final songs = context.select((PlaybackStateCubit c) => c.state.currentPlaylist);
    final currentIndex = context.select((AudioControlCubit c) => c.state.currentIndex);
    final appDirectory = context.select((LibraryCubit c) => c.state.appDirectory);

    // Sync to an external song change (buttons / auto-advance) without fighting
    // an in-progress user swipe. This move is programmatic, so clear the swipe
    // latch to be sure its onPageChanged doesn't seek.
    if (currentIndex != _activeIndex && !_isUserDragging) {
      _activeIndex = currentIndex;
      _userSwipe = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isUserDragging || !_controller.hasClients) return;
        if (_controller.page?.round() != currentIndex) {
          _controller.animateToPage(
            currentIndex,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }

    if (songs.isEmpty) return SizedBox(height: widget.height);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          GestureDetector(
            onVerticalDragStart: (_) {
              _isVolumeDragging = true;
              _hideTimer?.cancel();
              if (!_showVolumeSlider) setState(() => _showVolumeSlider = true);
            },
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: (_) {
              _isVolumeDragging = false;
              _restartHideTimer();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // A non-null dragDetails means the user is physically dragging;
                // animateToPage produces notifications without it.
                if (notification is ScrollStartNotification) {
                  _isUserDragging = true;
                  if (notification.dragDetails != null) _userSwipe = true;
                } else if (notification is ScrollEndNotification) {
                  _isUserDragging = false;
                }
                return false;
              },
              child: PageView.builder(
                controller: _controller,
                itemCount: songs.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  final imageFile = File('$appDirectory/${song.albumId}.jpg');
                  final radius = BorderRadius.circular(15);

                  Widget image = ClipRRect(
                    borderRadius: radius,
                    child: Image.file(
                      imageFile,
                      width: double.infinity,
                      height: widget.height,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => ArtworkImage(
                        artworkId: song.id,
                        type: ArtworkType.AUDIO,
                        width: double.infinity,
                        height: widget.height,
                        size: 500,
                        radius: radius,
                      ),
                    ),
                  );

                  // Hero only on the active page so the open/close transition keeps
                  // flying the current artwork (a single tag stays on screen).
                  if (index == currentIndex) {
                    image = Hero(tag: widget.currentHeroId, child: image);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: image,
                  );
                },
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showVolumeSlider ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: _buildVolumeOverlay(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongPlayedPortraitBody extends StatelessWidget {
  const _SongPlayedPortraitBody({
    required this.playAnimation,
    required this.songPlayed,
    required this.imageFile,
    required this.isFavoriteSong,
    required this.currentHeroId,
    required this.playbackState,
    required this.libraryState,
  });

  final AnimationController? playAnimation;
  final SongModel songPlayed;
  final File imageFile;
  final bool isFavoriteSong;
  final String currentHeroId;
  final PlaybackState playbackState;
  final LibraryState libraryState;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _ArtworkCarousel(
              currentHeroId: currentHeroId,
              height: 350,
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: size.height * 0.075,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CustomIconButton(
                    icon: isFavoriteSong
                        ? Icons.favorite
                        : Icons.favorite_border,
                    onPressed: () => _toggleFavorite(context, songPlayed),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: songPlayed.title.value().length > 25
                              ? SizedBox(
                                  height: 40,
                                  child: Marqueer(
                                    pps: 45.0,
                                    child: Text(
                                      songPlayed.title.value(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 10),
                                    Text(
                                      songPlayed.title.value(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                  ],
                                ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                _navigateToArtist(context, libraryState, songPlayed),
                            child: Text(
                              songPlayed.artist.valueEmpty('No Artist'),
                              textScaler: const TextScaler.linear(1),
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                              ).copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
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
                  ),
                ],
              ),
            ),
            const Spacer(),
            const _SongTimeline(),
            const Spacer(),
            _MusicControls(playAnimation: playAnimation),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _CustomIconButton extends StatelessWidget {
  const _CustomIconButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final songPlayedThemeColor =
        context.select((UICubit c) => c.state.songPlayedThemeColor);

    return IconButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, color: songPlayedThemeColor),
    );
  }
}

void _toggleFavorite(BuildContext context, SongModel songPlayed) {
  final favoritesState = context.read<FavoritesCubit>().state;
  final libraryState = context.read<LibraryCubit>().state;
  audioPlayerHandler<FavoritesService>().toggle(
    songPlayed,
    favoritesState: favoritesState,
    allSongs: libraryState.songList,
  );
}

void _navigateToArtist(
  BuildContext context,
  LibraryState libraryState,
  SongModel songPlayed,
) {
  final artistId = songPlayed.artistId;
  if (artistId == null || artistId == 0) return;

  final artist = libraryState.artistList.firstWhere(
    (a) => a.id == artistId.value(),
    orElse: () => ArtistModel({'_id': 0}),
  );
  if (artist.id == 0) return;

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ArtistSelectedScreen(artistSelected: artist)),
  );
}

class _MusicControls extends StatefulWidget {
  const _MusicControls({required this.playAnimation});

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
    final audioControlState = context.read<AudioControlCubit>().state;
    final playbackState = context.read<PlaybackStateCubit>().state;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton(
          heroTag: 'forward',
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          onPressed: () async {
            final next = audioPlayer.loopMode == LoopMode.off
                ? LoopMode.one
                : audioPlayer.loopMode == LoopMode.one
                    ? LoopMode.all
                    : LoopMode.off;
            await audioPlayer.setLoopMode(next);
            Fluttertoast.showToast(
              msg: next == LoopMode.off
                  ? 'Order'
                  : next == LoopMode.one
                      ? 'Repeat Current'
                      : 'Repeat On',
            );
          },
          child: StreamBuilder(
            stream: audioPlayer.loopModeStream,
            builder: (_, AsyncSnapshot<LoopMode> snap) {
              if (!snap.hasData) return const Icon(Icons.forward);
              return Icon(
                snap.data == LoopMode.off
                    ? Icons.repeat
                    : snap.data == LoopMode.one
                        ? Icons.repeat_one
                        : Icons.keyboard_double_arrow_right,
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Listener(
              onPointerDown: (_) {
                setState(() => _buttonPressed = true);
                _whilePressed(
                  audioPlayer: audioPlayer,
                  currentIndex: audioControlState.currentIndex,
                  songDurationSeconds: Duration(
                    milliseconds: playbackState.songPlayed.duration.value(),
                  ).inSeconds,
                  goToSeconds: -10,
                );
              },
              onPointerUp: (_) => setState(() => _buttonPressed = false),
              child: FloatingActionButton(
                heroTag: 'fast_rewind',
                elevation: 0.0,
                highlightElevation: 0.0,
                splashColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                onPressed: () async {
                  setState(() => _buttonPressed = false);
                  await audioPlayer.seekToPrevious();
                },
                child: const Icon(Icons.skip_previous),
              ),
            ),
            const SizedBox(width: 15),
            StreamBuilder<bool>(
              stream: audioPlayer.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? audioPlayer.playing;
                if (isPlaying) {
                  widget.playAnimation?.forward();
                } else {
                  widget.playAnimation?.reverse();
                }
                return Bouncing(
                  child: FloatingActionButton(
                    heroTag: 'play_pause',
                    shape: isPlaying ? null : const CircleBorder(),
                    onPressed: () {
                      if (isPlaying) {
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
                      color: onSurfaceColor == Colors.white
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 15),
            Listener(
              onPointerDown: (_) async {
                setState(() => _buttonPressed = true);
                _whilePressed(
                  audioPlayer: audioPlayer,
                  currentIndex: audioControlState.currentIndex,
                  songDurationSeconds: Duration(
                    milliseconds: playbackState.songPlayed.duration.value(),
                  ).inSeconds,
                  goToSeconds: 10,
                );
              },
              onPointerUp: (_) => setState(() => _buttonPressed = false),
              child: FloatingActionButton(
                heroTag: 'fast_forward',
                elevation: 0.0,
                highlightElevation: 0.0,
                backgroundColor: Colors.transparent,
                onPressed: () async {
                  setState(() => _buttonPressed = false);
                  await audioPlayer.seekToNext();
                },
                child: const Icon(Icons.skip_next_sharp),
              ),
            ),
          ],
        ),
        FloatingActionButton(
          heroTag: 'shuffle',
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          onPressed: () {
            audioPlayer.setShuffleModeEnabled(!audioPlayer.shuffleModeEnabled);
            Fluttertoast.showToast(
              msg: 'Shuffle ${audioPlayer.shuffleModeEnabled ? 'ON' : 'OFF'}',
            );
          },
          child: StreamBuilder(
            stream: audioPlayer.shuffleModeEnabledStream,
            builder: (_, AsyncSnapshot<bool> snap) {
              if (!snap.hasData) {
                return Icon(Icons.shuffle,
                    color: onSurfaceColor.withValues(alpha: 0.6));
              }
              return Icon(
                Icons.shuffle,
                color: snap.data!
                    ? onSurfaceColor
                    : onSurfaceColor.withValues(alpha: 0.6),
              );
            },
          ),
        ),
      ],
    );
  }

  void _whilePressed({
    required AudioPlayer audioPlayer,
    required int currentIndex,
    required int songDurationSeconds,
    required int goToSeconds,
  }) async {
    if (_loopActive) return;
    _loopActive = true;

    // Wait before the first seek so a quick tap (skip to next/previous song)
    // doesn't trigger a scrub jump. Scrubbing only starts while held.
    await Future.delayed(const Duration(milliseconds: 500));

    while (_buttonPressed) {
      if (currentIndex != audioPlayer.currentIndex) {
        _buttonPressed = false;
        break;
      }

      // Read the live position so holding scrubs progressively.
      final secondsResult = audioPlayer.position.inSeconds + goToSeconds;

      if (secondsResult <= 0 || secondsResult >= songDurationSeconds) {
        _buttonPressed = false;
      }

      audioPlayer.seek(
        Duration(seconds: secondsResult.clamp(0, songDurationSeconds)),
      );
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _loopActive = false;
  }
}

class _SongTimeline extends StatelessWidget {
  const _SongTimeline();

  @override
  Widget build(BuildContext context) {
    final audioPlayer = audioPlayerHandler<AudioPlayer>();
    final audioControlState = context.watch<AudioControlCubit>().state;
    final songPlayed = context.read<PlaybackStateCubit>().state.songPlayed;

    return ProgressBar(
      thumbGlowRadius: 15.0,
      thumbRadius: 8.0,
      barHeight: 3.0,
      progress: audioControlState.currentDuration,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: audioPlayer.seek,
      timeLabelTextStyle: const TextStyle(fontWeight: FontWeight.w500)
          .copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

class _SongPlayedLandscapeBody extends StatelessWidget {
  const _SongPlayedLandscapeBody({
    required this.playAnimation,
    required this.isPlaylist,
    required this.playlistId,
    required this.songPlayed,
    required this.imageFile,
    required this.isFavoriteSong,
    required this.currentHeroId,
    required this.playbackState,
    required this.libraryState,
  });

  final AnimationController? playAnimation;
  final bool isPlaylist;
  final int playlistId;
  final SongModel songPlayed;
  final File imageFile;
  final bool isFavoriteSong;
  final String currentHeroId;
  final PlaybackState playbackState;
  final LibraryState libraryState;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
                child: _ArtworkCarousel(
                  currentHeroId: currentHeroId,
                  height: 330,
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
                          playlistId: playlistId,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: size.height * 0.34,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () => _toggleFavorite(context, songPlayed),
                            icon: Icon(
                              isFavoriteSong
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                            ),
                          ),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: songPlayed.title.value().length > 25
                                      ? Marqueer(
                                          pps: 50.0,
                                          child: Text(
                                            songPlayed.title.value(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w400,
                                              fontSize: 18,
                                            ),
                                          ),
                                        )
                                      : Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(height: 10),
                                            Text(
                                              songPlayed.title.value(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 9),
                                          ],
                                        ),
                                ),
                                if (songPlayed.artist.value().length > 30)
                                  const SizedBox(height: 5),
                                InkWell(
                                  onTap: () => _navigateToArtist(
                                    context,
                                    libraryState,
                                    songPlayed,
                                  ),
                                  child: Text(
                                    songPlayed.artist.valueEmpty('No Artist'),
                                    textScaler: const TextScaler.linear(1.0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                MusicActions.showCurrentPlayList(context),
                            icon: const Icon(Icons.playlist_play),
                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
