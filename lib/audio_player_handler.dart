
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:get_it/get_it.dart';

GetIt audioPlayerHandler = GetIt.instance;

void setupAudioPlayerHandler() {
  audioPlayerHandler.registerLazySingleton(() => AssetsAudioPlayer() );
}