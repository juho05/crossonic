import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:crossonic/app.dart';
import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/features/browse/state/browse_bloc.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/offline_cache/offline_cache.dart';
import 'package:crossonic/services/audio_handler/players/audioplayers.dart';
import 'package:crossonic/services/audio_handler/players/gstreamer.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:crossonic/services/audio_handler/integrations/integration.dart';
import 'package:crossonic/services/scrobble/scrobbler.dart';
import 'package:crossonic/components/state/favorites_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1300, 850),
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
  final apiRepository = await APIRepository.init();

  final settings = Settings(
      sharedPreferences: sharedPreferences, apiRepository: apiRepository);

  final offlineCache = OfflineCache(
    apiRepository: apiRepository,
  );

  final playlistRepository = PlaylistRepository(
      apiRepository: apiRepository,
      sharedPreferences: sharedPreferences,
      offlineCache: offlineCache);
  await playlistRepository.init();

  final CrossonicAudioPlayer audioPlayer;
  final NativeIntegration nativeIntegration;
  if (!kIsWeb && Platform.isWindows) {
    nativeIntegration = SMTCIntegration();
  } else {
    var androidBackgroundAvailable = true;
    if (!kIsWeb && Platform.isAndroid) {
      androidBackgroundAvailable =
          await OptimizeBattery.isIgnoringBatteryOptimizations();
      if (!androidBackgroundAvailable) {
        await OptimizeBattery.stopOptimizingBatteryUsage();
        // because there is no way to know when/if the user clicks yes on the dialog
        // androidBackgroundAvailable stays false until the next start of the app
      }
    }

    final audioService = await AudioService.init(
        builder: () => AudioServiceIntegration(
            apiRepository: apiRepository,
            playlistRepository: playlistRepository),
        config: AudioServiceConfig(
          androidNotificationChannelId: "de.julianh.crossonic",
          androidNotificationChannelName: "Music playback",
          androidNotificationIcon: "drawable/ic_stat_crossonic",
          androidStopForegroundOnPause: androidBackgroundAvailable,
          androidNotificationChannelDescription: "Playback notification",
        ));
    nativeIntegration = audioService;
  }

  final audioSession = await AudioSession.instance;
  if (!kIsWeb &&
      (Platform.isLinux ||
          Platform.isAndroid ||
          Platform.isMacOS ||
          Platform.isWindows)) {
    audioPlayer = AudioPlayerGstreamer(audioSession);
  } else {
    audioPlayer = AudioPlayerAudioPlayers();
  }
  await audioSession.configure(const AudioSessionConfiguration.music());

  final audioHandler = CrossonicAudioHandler(
    apiRepository: apiRepository,
    player: audioPlayer,
    integration: nativeIntegration,
    settings: settings,
    offlineCache: offlineCache,
  );

  Scrobbler.enable(
    sharedPreferences: sharedPreferences,
    audioHandler: audioHandler,
    apiRepository: apiRepository,
  );

  runApp(MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: apiRepository),
      RepositoryProvider.value(value: audioHandler),
      RepositoryProvider.value(value: settings),
      RepositoryProvider.value(value: playlistRepository),
      RepositoryProvider(create: (context) => Layout(size: LayoutSize.mobile))
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc(apiRepository: apiRepository)),
        BlocProvider(create: (_) => NowPlayingCubit(audioHandler)),
        BlocProvider(create: (_) => BrowseBloc(apiRepository)),
        BlocProvider(create: (_) => FavoritesCubit(apiRepository)),
      ],
      child: const App(),
    ),
  ));
}
