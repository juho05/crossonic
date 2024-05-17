import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:crossonic/app.dart';
import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/features/home/view/state/random_songs_cubit.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/features/home/view/state/recently_added_albums_cubit.dart';
import 'package:crossonic/features/search/state/search_bloc.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/services/audio_player/audio_handler.dart';
import 'package:crossonic/services/audio_player/audio_handler_gstreamer.dart';
import 'package:crossonic/services/audio_player/audio_handler_justaudio.dart';
import 'package:crossonic/services/audio_player/audio_handler_audioplayers.dart';
import 'package:crossonic/services/audio_player/native_notifier/native_notifier.dart';
import 'package:crossonic/services/audio_player/scrobble/scrobbler.dart';
import 'package:crossonic/widgets/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      center: true,
      title: "Crossonic",
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  final apiRepository = APIRepository();
  final CrossonicAudioHandler audioHandler;
  final NativeNotifier nativeNotifier;
  if (!kIsWeb && Platform.isWindows) {
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

  if (kIsWeb || Platform.isAndroid) {
    audioHandler = CrossonicAudioHandlerJustAudio(
      apiRepository: apiRepository,
      notifier: nativeNotifier,
    );
  } else if (Platform.isLinux) {
    audioHandler = CrossonicAudioHandlerGstreamer(
      apiRepository: apiRepository,
      notifier: nativeNotifier,
    );
  } else {
    audioHandler = CrossonicAudioHandlerAudioPlayers(
      apiRepository: apiRepository,
      notifier: nativeNotifier,
    );
  }
  final audioSession = await AudioSession.instance;
  audioSession.configure(const AudioSessionConfiguration.music());

  Scrobbler.enable(
    sharedPreferences: sharedPreferences,
    audioHandler: audioHandler,
  );

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: apiRepository),
      RepositoryProvider.value(value: audioHandler),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(apiRepository: apiRepository)),
        BlocProvider(
          create: (_) => RandomSongsCubit(apiRepository)..fetch(50),
        ),
        BlocProvider(
          create: (_) => RecentlyAddedAlbumsCubit(apiRepository)..fetch(15),
        ),
        BlocProvider(create: (_) => NowPlayingCubit(audioHandler)),
        BlocProvider(create: (_) => SearchBloc(apiRepository)),
        BlocProvider(create: (_) => FavoritesCubit(apiRepository)),
      ],
      child: const App(),
    ),
  ));
}
