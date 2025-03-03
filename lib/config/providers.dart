import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart' as ah;
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
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

  final subsonicService = SubsonicService();

  final keyValueRepository = KeyValueRepository(database: database);

  final authRepository = AuthRepository(
    openSubsonicService: subsonicService,
    keyValueRepository: keyValueRepository,
    database: database,
  );
  await authRepository.loadState();

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
        builder: () => AudioServiceIntegration(),
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
      value: subsonicService,
    ),
    ChangeNotifierProvider.value(
      value: authRepository,
    ),
    Provider(
      create: (context) => CoverRepository(
        authRepository: context.read(),
        subsonicService: context.read(),
      ),
      dispose: (context, value) => value.dispose(),
    ),
    ChangeNotifierProvider(
      create: (context) => FavoritesRepository(
        auth: context.read(),
        subsonic: context.read(),
      ),
    ),
    Provider(
      create: (context) => SubsonicRepository(
        authRepository: context.read(),
        subsonicService: context.read(),
        favoritesRepository: context.read(),
      ),
    ),
    Provider(
      create: (context) => ah.AudioHandler(
        player: audioPlayer,
        integration: mediaIntegration,
        authRepository: authRepository,
        subsonicService: subsonicService,
      ),
    )
  ];
}
