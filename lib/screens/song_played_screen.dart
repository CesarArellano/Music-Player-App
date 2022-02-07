import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:music_player_app/providers/audio_control_provider.dart';
import 'package:music_player_app/providers/music_player_provider.dart';
import 'package:music_player_app/widgets/widgets.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:provider/provider.dart';

import '../providers/audio_control_provider.dart';

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
            onPressed: (){
              showModalBottomSheet(
                context: context,
                builder: ( ctx ) => Container(
                color: const Color(0xCC174A85),
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: musicPlayerProvider.audioPlayer.playlist?.audios.length,
                    itemBuilder: (_, int i) {
                      final audioControlProvider = Provider.of<AudioControlProvider>(context);
                      final audio = musicPlayerProvider.audioPlayer.playlist?.audios[i];
                      return ListTile(
                        leading: const Icon( Icons.music_note, color: Colors.white, ),
                        title: Text(audio!.metas.title!, maxLines: 1),
                        subtitle: Text(audio.metas.artist!, maxLines: 1),
                        onTap: () {
                          musicPlayerProvider.audioPlayer.playlistPlayAtIndex(i);
                          audioControlProvider.currentIndex = i;
                          musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[i];
                          Navigator.pop(ctx);
                        },
                      );
                    }
                  ),
                )
              );
            },
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
              format: ArtworkFormat.JPEG,
              type: ArtworkType.AUDIO,
              artworkBorder: BorderRadius.zero,
              artworkWidth: double.infinity,
              artworkHeight: 350,
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
                  Text(songPlayed.artist ?? 'No Artist', style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 16, color: Colors.white54)),
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
            stream: musicPlayerProvider.audioPlayer.loopMode,
            builder: (BuildContext context, AsyncSnapshot<LoopMode> snapshot) {  
              if( !snapshot.hasData ) {
                return const Icon( Icons.forward );
              }
              return Icon( ( snapshot.data == LoopMode.none ) ? Icons.forward : Icons.repeat_one );
            },
          ),
          onPressed: () async {
            await musicPlayerProvider.audioPlayer.setLoopMode( 
              musicPlayerProvider.audioPlayer.loopMode.value == LoopMode.none
              ? LoopMode.single
              : LoopMode.none
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              elevation: 0.0,
              highlightElevation: 0.0,
              backgroundColor: Colors.transparent,
              child: const Icon( Icons.fast_rewind),
              onPressed: () {
                if( musicPlayerProvider.audioPlayer.loopMode.value == LoopMode.none && controlProvider.currentIndex > 0 ) {
                  controlProvider.currentIndex -= 1;
                  musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[controlProvider.currentIndex];
                  musicPlayerProvider.audioPlayer.previous();
                }
              },
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
              backgroundColor: Colors.transparent,
              child: const Icon( Icons.fast_forward ),
              onPressed: () {
                if( musicPlayerProvider.audioPlayer.loopMode.value == LoopMode.none && controlProvider.currentIndex <= musicPlayerProvider.currentPlaylist.length - 2 ) {
                  controlProvider.currentIndex += 1;
                  musicPlayerProvider.songPlayed = musicPlayerProvider.currentPlaylist[controlProvider.currentIndex];
                  musicPlayerProvider.audioPlayer.next();
                }
              },
              
            ),
          ]
        ),
        FloatingActionButton(
          elevation: 0.0,
          highlightElevation: 0.0,
          backgroundColor: Colors.transparent,
          child: StreamBuilder(
            stream: musicPlayerProvider.audioPlayer.isShuffling,
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
    final audioControlProvider = Provider.of<AudioControlProvider>(context);
    final musicPlayerProvider = Provider.of<MusicPlayerProvider>(context, listen: false);
    final songPlayed = musicPlayerProvider.songPlayed;

    return ProgressBar(
      thumbGlowRadius: 15.0,
      thumbRadius: 8.0,
      barHeight: 3.0,
      progressBarColor: Colors.white,
      thumbColor: Colors.amber,
      progress: audioControlProvider.current,
      total: Duration(milliseconds: songPlayed.duration!),
      onSeek: (duration) {
        musicPlayerProvider.audioPlayer.seek(duration);
      },
    );
  }
}