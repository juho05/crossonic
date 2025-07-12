import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:crossonic/data/repositories/audio/audio_handler.dart' as ah;
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/downloader_storage.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/scrobble/scrobbler.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/data/services/audio_players/audioplayers.dart';
import 'package:crossonic/data/services/audio_players/gstreamer.dart';
import 'package:crossonic/data/services/audio_players/plugin.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/github/github.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<List<SingleChildWidget>> get providers async {
  final database = Database();

  if (!kIsWeb) {
    await DownloaderStorage.register(database);
    bd.FileDownloader().configure(
      globalConfig: [
        // limit concurrent downloads per group to 5
        (bd.Config.holdingQueue, (null, null, 5)),
      ],
    );
  }

  final subsonicService = SubsonicService();

  final keyValueRepository = KeyValueRepository(database: database);

  AuthRepository authRepository;
  try {
    authRepository = AuthRepository(
      openSubsonicService: subsonicService,
      keyValueRepository: keyValueRepository,
      database: database,
    );
    await authRepository.loadState();
  } on Exception catch (e, st) {
    Log.critical("Failed to initialize auth repository", e, st);
    exit(1);
  }

  final favoritesRepository = FavoritesRepository(
    auth: authRepository,
    subsonic: subsonicService,
    database: database,
  );

  final subsonicRepository = SubsonicRepository(
    authRepository: authRepository,
    subsonicService: subsonicService,
    favoritesRepository: favoritesRepository,
  );

  final settings = SettingsRepository(
    authRepository: authRepository,
    keyValueRepository: keyValueRepository,
    subsonic: subsonicRepository,
  );

  final songDownloader = SongDownloader(
    db: database,
    auth: authRepository,
    subsonic: subsonicService,
  );
  if (!kIsWeb) {
    await songDownloader.init();
    await bd.FileDownloader().resumeFromBackground();
    Timer(const Duration(seconds: 5), () {
      bd.FileDownloader().rescheduleKilledTasks();
    });
  }

  final coverRepository = CoverRepository(
    authRepository: authRepository,
    subsonicService: subsonicService,
  );

  final playlistRepository = PlaylistRepository(
    subsonic: subsonicService,
    favorites: favoritesRepository,
    auth: authRepository,
    db: database,
    coverRepository: coverRepository,
    songDownloader: songDownloader,
  );

  final MediaIntegration mediaIntegration;
  if (!kIsWeb && Platform.isWindows) {
    mediaIntegration = SMTCIntegration();
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
      builder: () =>
          AudioServiceIntegration(playlistRepository: playlistRepository),
      config: AudioServiceConfig(
        androidNotificationChannelId: "org.crossonic.app",
        androidNotificationChannelName: "Music playback",
        androidNotificationIcon: "drawable/ic_stat_crossonic",
        androidStopForegroundOnPause: androidBackgroundAvailable,
        androidNotificationChannelDescription: "Playback notification",
      ),
      cacheManager: coverRepository,
    );
    mediaIntegration = audioService;
  }

  final AudioPlayer audioPlayer;
  final audioSession = await AudioSession.instance;
  if (!kIsWeb &&
      (Platform.isLinux ||
          Platform.isMacOS ||
          Platform.isWindows ||
          Platform.isIOS)) {
    audioPlayer = AudioPlayerGstreamer(audioSession);
  } else if (!kIsWeb && Platform.isAndroid) {
    audioPlayer = AudioPlayerPlugin(audioSession);
  } else {
    audioPlayer = AudioPlayerAudioPlayers();
  }
  await audioSession.configure(const AudioSessionConfiguration.music());

  return [
    Provider.value(
      value: database,
    ),
    Provider.value(
      value: keyValueRepository,
    ),
    Provider(
      create: (context) => GitHubService(),
    ),
    Provider(
      create: (context) => VersionRepository(
        github: context.read(),
        keyValue: context.read(),
      ),
    ),
    Provider.value(
      value: subsonicService,
    ),
    ChangeNotifierProvider.value(
      value: authRepository,
    ),
    ChangeNotifierProvider.value(
      value: favoritesRepository,
    ),
    ChangeNotifierProvider.value(
      value: songDownloader,
    ),
    Provider.value(
      value: subsonicRepository,
    ),
    Provider.value(
      value: settings,
    ),
    Provider.value(
      value: coverRepository,
    ),
    Provider(
      create: (context) => ah.AudioHandler(
        player: audioPlayer,
        integration: mediaIntegration,
        authRepository: context.read(),
        subsonicService: context.read(),
        settingsRepository: context.read(),
        songDownloader: context.read(),
      ),
    ),
    Provider(
      create: (context) => Scrobbler.enable(
          audioHandler: context.read(),
          authRepository: context.read(),
          database: context.read(),
          subsonicService: context.read()),
      dispose: (context, value) => value.dispose(),
      lazy: false,
    ),
    ChangeNotifierProvider.value(
      value: playlistRepository,
    )
  ];
}
