/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:crossonic/data/repositories/androidauto/androidauto_repository.dart';
import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart' as ah;
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/data/repositories/playlist/downloader_storage.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/scrobble/scrobbler.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/song/song_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/repositories/themeManager/theme_manager.dart';
import 'package:crossonic/data/repositories/version/version_repository.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/github/github.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/media_integration/noop_integration.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/integrate_appimage_viewmodel.dart';
import 'package:crossonic/version_checker_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<List<SingleChildWidget>> createProviders({
  required MethodChannelService methodChannelService,
  required LogRepository logRepository,
}) async {
  final database = Database();

  await logRepository.enablePersistence(database);

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
    Log.fatal("Failed to initialize auth repository", e: e, st: st);
    exit(1);
  }

  final favoritesRepository = FavoritesRepository(
    auth: authRepository,
    subsonic: subsonicService,
    database: database,
  );

  final songRepository = SongRepository(
    db: database,
    favorites: favoritesRepository,
  );

  final musicFoldersRepo = MusicFoldersRepository(
    auth: authRepository,
    subsonic: subsonicService,
    keyValue: keyValueRepository,
  );
  await musicFoldersRepo.load();

  final subsonicRepository = SubsonicRepository(
    authRepository: authRepository,
    subsonicService: subsonicService,
    favoritesRepository: favoritesRepository,
    songRepository: songRepository,
    musicFoldersRepository: musicFoldersRepo,
  );

  final settings = SettingsRepository(
    authRepository: authRepository,
    keyValueRepository: keyValueRepository,
    subsonic: subsonicRepository,
  );
  await settings.load();

  final songDownloader = SongDownloader(
    db: database,
    auth: authRepository,
    subsonic: subsonicService,
  );
  if (!kIsWeb) {
    await songDownloader.init();
    Log.debug("resuming download tasks from background");
    await bd.FileDownloader().resumeFromBackground();
    Timer(const Duration(seconds: 5), () {
      Log.debug("rescheduling killed download tasks");
      bd.FileDownloader().rescheduleKilledTasks();
    });
  }

  final coverRepository = CoverRepository(
    authRepository: authRepository,
    subsonicRepository: subsonicRepository,
    database: database,
  );

  final playlistRepository = PlaylistRepository(
    subsonic: subsonicService,
    auth: authRepository,
    db: database,
    coverRepository: coverRepository,
    songDownloader: songDownloader,
    songRepository: songRepository,
  );

  final MediaIntegration mediaIntegration;
  if (!kIsWeb && Platform.isWindows) {
    Log.debug("initializing audio service");
    mediaIntegration = SMTCIntegration();
  } else {
    if (!kIsWeb &&
        Platform.isAndroid &&
        !(const bool.fromEnvironment("PLAYSTORE", defaultValue: false))) {
      if (!await OptimizeBattery.isIgnoringBatteryOptimizations()) {
        Log.info("battery optimization is not disabled, asking user...");
        await OptimizeBattery.stopOptimizingBatteryUsage();
      } else {
        Log.info("battery optimization is disabled");
      }
    }

    Log.debug("initializing audio service");
    if (!kIsWeb && Platform.isAndroid) {
      mediaIntegration = NoopIntegration();
    } else {
      final audioService = await AudioService.init(
        builder: () =>
            AudioServiceIntegration(playlistRepository: playlistRepository),
        config: const AudioServiceConfig(
          androidNotificationChannelId: "org.crossonic.app",
          androidNotificationChannelName: "Music playback",
          androidNotificationIcon: "drawable/ic_stat_crossonic",
          androidNotificationChannelDescription: "Playback notification",
        ),
        cacheManager: kIsWeb ? null : coverRepository,
      );
      mediaIntegration = audioService;
    }
  }

  return [
    Provider.value(value: methodChannelService),
    Provider.value(value: logRepository),
    ChangeNotifierProvider(
      create: (context) => ThemeManager(
        keyValue: keyValueRepository,
        appearanceSettings: settings.appearanceSettings,
      ),
      lazy: false,
    ),
    Provider.value(value: database),
    Provider.value(value: keyValueRepository),
    Provider(create: (context) => GitHubService()),
    Provider(
      create: (context) =>
          VersionRepository(github: context.read(), keyValue: context.read()),
    ),
    Provider.value(value: subsonicService),
    ChangeNotifierProvider.value(value: authRepository),
    ChangeNotifierProvider.value(value: musicFoldersRepo),
    ChangeNotifierProvider.value(value: favoritesRepository),
    ChangeNotifierProvider.value(value: songDownloader),
    Provider.value(value: subsonicRepository),
    Provider.value(value: settings),
    Provider.value(value: coverRepository),
    Provider(
      create: (context) => ah.AudioHandler(
        methodChannel: methodChannelService,
        coverRepository: coverRepository,
        integration: mediaIntegration,
        authRepository: context.read(),
        subsonicRepository: context.read(),
        settingsRepository: context.read(),
        songDownloader: context.read(),
        keyValueRepository: context.read(),
        songRepository: songRepository,
        database: database,
      ),
      lazy: false,
    ),
    Provider(
      create: (context) => Scrobbler.enable(
        audioHandler: context.read(),
        authRepository: context.read(),
        database: context.read(),
        subsonicService: context.read(),
      ),
      dispose: (context, value) => value.dispose(),
      lazy: false,
    ),
    if (!kIsWeb && Platform.isAndroid)
      Provider(
        create: (context) => AndroidAutoRepository(
          methodChannel: methodChannelService,
          subsonicRepo: subsonicRepository,
          playlistRepo: playlistRepository,
          coverRepository: coverRepository,
          audioHandler: context.read(),
        ),
        lazy: false,
      ),
    ChangeNotifierProvider.value(value: playlistRepository),
    ChangeNotifierProvider(
      create: (context) => VersionCheckerViewModel(
        keyValue: context.read(),
        versionRepo: context.read(),
        settings: context.read(),
      )..check(),
    ),
    if (AppImageRepository.isAppImage)
      Provider(
        create: (context) => AppImageRepository(keyValue: context.read()),
      ),
    if (AppImageRepository.isAppImage)
      ChangeNotifierProvider(
        create: (context) =>
            IntegrateAppImageViewModel(appImageRepository: context.read())
              ..check(),
      ),
    if (AutoUpdateRepository.autoUpdatesSupported)
      ChangeNotifierProvider(
        create: (context) => AutoUpdateRepository(
          versionRepository: context.read(),
          github: context.read(),
        ),
      ),
  ];
}
