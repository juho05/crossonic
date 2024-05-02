import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:crossonic/app.dart';
import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/features/home/view/state/recently_added_albums_cubit.dart';
import 'package:crossonic/features/search/state/search_bloc.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:crossonic/repositories/crossonic/crossonic.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/audio_handler_justaudio.dart';
import 'package:crossonic/services/audio_player/audio_handler_audioplayers.dart';
import 'package:crossonic/services/audio_player/native_notifier/native_notifier.dart';
import 'package:crossonic/services/audio_player/scrobble/scrobbler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      title: "Crossonic",
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  final authRepository = AuthRepository();
  final crossonicRepository = CrossonicRepository(authRepository);
  final subsonicRepository = SubsonicRepository(authRepository);
  final CrossonicAudioHandler audioHandler;
  final NativeNotifier nativeNotifier;
  if (Platform.isWindows) {
    nativeNotifier = NativeNotifierSMTC();
  } else {
    final audioService = await AudioService.init(
        builder: () => NativeNotifierAudioService(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: "de.julianh.crossonic",
          androidNotificationChannelName: "Music playback",
        ));
    nativeNotifier = audioService;
  }

  if (Platform.isWindows || Platform.isLinux) {
    audioHandler = CrossonicAudioHandlerAudioPlayers(
      subsonicRepository: subsonicRepository,
      notifier: nativeNotifier,
    );
  } else {
    audioHandler = CrossonicAudioHandlerJustAudio(
      subsonicRepository: subsonicRepository,
      notifier: nativeNotifier,
    );
  }
  final audioSession = await AudioSession.instance;
  audioSession.configure(const AudioSessionConfiguration.music());

  Scrobbler.enable(
    sharedPreferences: sharedPreferences,
    audioHandler: audioHandler,
    crossonicRepository: crossonicRepository,
  );

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: authRepository),
      RepositoryProvider.value(value: subsonicRepository),
      RepositoryProvider.value(value: crossonicRepository),
      RepositoryProvider.value(value: audioHandler),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(authRepository: authRepository)),
        BlocProvider(
          create: (_) => RandomSongsCubit(subsonicRepository)..fetch(50),
        ),
        BlocProvider(
          create: (_) =>
              RecentlyAddedAlbumsCubit(subsonicRepository)..fetch(15),
        ),
        BlocProvider(create: (_) => NowPlayingCubit(audioHandler)),
        BlocProvider(create: (_) => SearchBloc(subsonicRepository)),
      ],
      child: const App(),
    ),
  ));
}
