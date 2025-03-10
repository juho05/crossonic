import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:crossonic/data/repositories/audio/audio_handler.dart' as ah;
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/playlist/downloader_storage.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/scrobble/scrobbler.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/audio_players/audioplayers.dart';
import 'package:crossonic/data/services/audio_players/gstreamer.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:optimize_battery/optimize_battery.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

Future<List<SingleChildWidget>> get providers async {
  final database = Database();

  DownloaderStorage.register(database);

  final subsonicService = SubsonicService();

  final keyValueRepository = KeyValueRepository(database: database);

  final authRepository = AuthRepository(
    openSubsonicService: subsonicService,
    keyValueRepository: keyValueRepository,
    database: database,
  );
  await authRepository.loadState();

  final songDownloader = SongDownloader(
    db: database,
    auth: authRepository,
    subsonic: subsonicService,
  );
  await songDownloader.init();
  await bd.FileDownloader().resumeFromBackground();
  Timer(Duration(seconds: 5), () {
    bd.FileDownloader().rescheduleKilledTasks();
  });

  final favoritesRepository = FavoritesRepository(
    auth: authRepository,
    subsonic: subsonicService,
  );
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
          androidNotificationChannelId: "de.julianh.crossonic",
          androidNotificationChannelName: "Music playback",
          androidNotificationIcon: "drawable/ic_stat_crossonic",
          androidStopForegroundOnPause: androidBackgroundAvailable,
          androidNotificationChannelDescription: "Playback notification",
        ));
    mediaIntegration = audioService;
  }

  final AudioPlayer audioPlayer;
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

  return [
    Provider.value(
      value: database,
    ),
    Provider.value(
      value: keyValueRepository,
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
    Provider.value(
      value: songDownloader,
    ),
    Provider(
      create: (context) => SubsonicRepository(
        authRepository: context.read(),
        subsonicService: context.read(),
        favoritesRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => SettingsRepository(
        authRepository: context.read(),
        keyValueRepository: context.read(),
        subsonic: context.read(),
      ),
      dispose: (context, value) => value.dispose(),
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
