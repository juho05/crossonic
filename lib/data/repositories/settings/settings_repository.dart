import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/settings/logging.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';

class SettingsRepository {
  final LoggingSettings logging;
  final ReplayGainSettings replayGain;
  final TranscodingSettings transcoding;
  final HomeLayoutSettings homeLayout;

  SettingsRepository({
    required AuthRepository authRepository,
    required KeyValueRepository keyValueRepository,
    required SubsonicRepository subsonic,
  })  : logging = LoggingSettings(
          keyValueRepository: keyValueRepository,
        ),
        replayGain = ReplayGainSettings(
          keyValueRepository: keyValueRepository,
        ),
        transcoding = TranscodingSettings(
          keyValueRepository: keyValueRepository,
          subsonicRepository: subsonic,
        ),
        homeLayout = HomeLayoutSettings(
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
    await logging.load();
    await Future.wait([
      replayGain.load(),
      transcoding.load(),
      homeLayout.load(),
    ]);
  }

  void dispose() {
    replayGain.dispose();
    transcoding.dispose();
    homeLayout.dispose();
    logging.dispose();
  }
}
