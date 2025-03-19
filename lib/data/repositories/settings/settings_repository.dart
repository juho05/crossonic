import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/settings/logging.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';

class SettingsRepository {
  final ReplayGainSettings replayGain;
  final TranscodingSettings transcoding;
  final LoggingSettings logging;

  SettingsRepository({
    required AuthRepository authRepository,
    required KeyValueRepository keyValueRepository,
    required SubsonicRepository subsonic,
  })  : replayGain = ReplayGainSettings(
          keyValueRepository: keyValueRepository,
        ),
        transcoding = TranscodingSettings(
          keyValueRepository: keyValueRepository,
          subsonicRepository: subsonic,
        ),
        logging = LoggingSettings(
          keyValueRepository: keyValueRepository,
        ) {
    bool wasAuthenticated = authRepository.isAuthenticated;
    if (authRepository.isAuthenticated) {
      load();
    }
    authRepository.addListener(() {
      if (authRepository.isAuthenticated) {
        load();
      } else if (wasAuthenticated) {
        logging.reset();
        Log.clear();
      }
      wasAuthenticated = authRepository.isAuthenticated;
    });
  }

  Future<void> load() async {
    await Future.wait([
      replayGain.load(),
      transcoding.load(),
      logging.load(),
    ]);
  }

  void dispose() {
    replayGain.dispose();
    transcoding.dispose();
    logging.dispose();
  }
}
