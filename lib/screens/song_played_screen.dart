import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/widgets/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

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
                Color(0xCC113763)
              ]
            ),
          )
        ),
        title: Column(
          children: [
            const Text('PLAYING FROM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400) ),
            const SizedBox(height: 4),
            Text(songPlayed.album ?? 'No Album', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]
        ),
        leading: IconButton(
          splashRadius: 22,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: <Widget>[
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.drag_indicator),
            onPressed: (){},
          ),
        ],
      ),
      body: Stack(
        children: [
          const CustomBackground(),
          _SongPlayedBody( playAnimation: _playAnimation ),
        ]
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.01),
            QueryArtworkWidget(
              keepOldArtwork: true,
              id: songPlayed.id,
              type: ArtworkType.AUDIO,
              artworkBorder: BorderRadius.zero,
              artworkWidth: double.infinity,
              artworkHeight: 350,
              artworkQuality: FilterQuality.high,
            ),
            SizedBox(height: size.height * 0.06),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton(
                  elevation: 0.0,
                  highlightElevation: 0.0,
                  onPressed: () {},
                  backgroundColor: Colors.transparent,
                  child: const Icon( Icons.library_add_check_sharp ),
                ),
                Column(
                  children: [
                    Text(songPlayed.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(songPlayed.artist ?? 'No Artist', style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 12)),
                  ],
                ),
                FloatingActionButton(
                  elevation: 0.0,
                  highlightElevation: 0.0,
                  onPressed: () {},
                  backgroundColor: Colors.transparent,
                  child: const Icon( Icons.list ),
                ),
              ],
            ),
            SizedBox(height: size.height * 0.1),
            const _SongTimeline(),
            SizedBox(height: size.height * 0.1),
            _MusicControls(musicPlayerProvider: musicPlayerProvider, playAnimation: playAnimation)
          ],
        ),
      ),
    );
  }
}

class _MusicControls extends StatelessWidget {
  const _MusicControls({
    Key? key,
    required this.musicPlayerProvider,
    required this.playAnimation,
  }) : super(key: key);

  final MusicPlayerProvider musicPlayerProvider;
  final AnimationController? playAnimation;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton(
          elevation: 0.0,
          highlightElevation: 0.0,
          onPressed: () {},
          backgroundColor: Colors.transparent,
          child: const Icon( Icons.repeat ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              elevation: 0.0,
              highlightElevation: 0.0,
              onPressed: () {},
              backgroundColor: Colors.transparent,
              child: const Icon( Icons.fast_rewind),
            ),
            const SizedBox(width: 15),
            FloatingActionButton(
              backgroundColor: Colors.amber,
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
              child: AnimatedIcon( 
                progress: playAnimation!,
                icon: AnimatedIcons.play_pause,
                color: Colors.black,
              )
            ),
            const SizedBox(width: 15),
            FloatingActionButton(
              elevation: 0.0,
              highlightElevation: 0.0,
              onPressed: () {},
              backgroundColor: Colors.transparent,
              child: const Icon( Icons.fast_forward ),
            ),
          ]
        ),
        FloatingActionButton(
          elevation: 0.0,
          highlightElevation: 0.0,
          onPressed: () {},
          backgroundColor: Colors.transparent,
          child: const Icon( Icons.shuffle ),
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
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context);
    final songPlayed = musicPlayerProvider.songPlayed;

    return ProgressBar(
      progressBarColor: Colors.white,
      thumbColor: Colors.amber,
      progress: musicPlayerProvider.current,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: (duration) {
        musicPlayerProvider.audioPlayer.seek(duration);
      },
    );
  }
}