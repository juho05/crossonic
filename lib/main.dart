import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:crossonic/app.dart';
import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/features/home/view/state/home_cubit.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  final authRepository = AuthRepository();
  final subsonicRepository = SubsonicRepository(authRepository);
  final audioHandler = await AudioService.init(
      builder: () =>
          CrossonicAudioHandler(subsonicRepository: subsonicRepository),
      config: const AudioServiceConfig(
        androidNotificationChannelId: "de.julianh.crossonic",
        androidNotificationChannelName: "Music playback",
      ));
  final audioSession = await AudioSession.instance;
  audioSession.configure(const AudioSessionConfiguration.music());
  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: authRepository),
      RepositoryProvider.value(value: subsonicRepository),
      RepositoryProvider.value(value: audioHandler),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)),
        BlocProvider(
          create: (_) => HomeCubit(subsonicRepository)..fetchRandomSongs(),
        ),
        BlocProvider(create: (_) => NowPlayingCubit(audioHandler)),
      ],
      child: const App(),
    ),
  ));
}
