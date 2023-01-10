
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

GetIt audioPlayerHandler = GetIt.instance;

void setupAudioHandlers() {
  audioPlayerHandler.registerLazySingleton(() => AudioPlayer() );
  audioPlayerHandler.registerLazySingleton(() => OnAudioQuery() );
}