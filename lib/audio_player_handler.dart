
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';

GetIt audioPlayerHandler = GetIt.instance;

void setupAudioHandlers() {
  audioPlayerHandler.registerLazySingleton(() => AssetsAudioPlayer() );
  audioPlayerHandler.registerLazySingleton(() => OnAudioQuery() );
}