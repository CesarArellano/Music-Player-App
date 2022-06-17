import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../audio_player_handler.dart';
import '../helpers/music_actions.dart';
import '../providers/audio_control_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/artwork_image.dart';
import '../widgets/widgets.dart';

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
        backgroundColor: const Color(0xFF001F42),
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
            onPressed: () => MusicActions.showCurrentPlayList(context),
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
            ArtworkImage(
              artworkId: songPlayed.id,
              type: ArtworkType.AUDIO,
              width: double.infinity,
              height: 350,
            ),
            SizedBox(height: size.height * 0.04),
            SizedBox(
              height: size.height * 0.07,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible (
                    child: ( songPlayed.title.length > 30 )
                    ? Marquee(
                      velocity: 50.0,
                      text: songPlayed.title,
                      blankSpace: 30,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    )
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        Text( songPlayed.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18) ),
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
            SizedBox(height: size.height * 0.1),
            const _SongTimeline(),
            SizedBox(height: size.height * 0.1),
            _MusicControls(playAnimation: playAnimation)
          ],
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
              audioPlayer.loopMode.value == LoopMode.none
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
                  if( audioPlayer.loopMode.value == LoopMode.none && controlProvider.currentIndex > 0 ) {
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
                  backgroundColor: Colors.amber,
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
                  if( audioPlayer.loopMode.value == LoopMode.none && controlProvider.currentIndex <= musicPlayerProvider.currentPlaylist.length - 2 ) {
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
      thumbColor: Colors.amber,
      progress: audioControlProvider.currentDuration,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: (duration) {
        audioPlayer.seek(duration);
      },
    );
  }
}