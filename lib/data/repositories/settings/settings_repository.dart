import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';

class SettingsRepository {
  final ReplayGainSettings replayGain;
  final TranscodingSettings transcoding;

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
        ) {
    if (authRepository.isAuthenticated) {
      load();
    }
    authRepository.addListener(() {
      if (authRepository.isAuthenticated) {
        load();
      }
    });
  }

  Future<void> load() async {
    await Future.wait([
      replayGain.load(),
      transcoding.load(),
    ]);
  }

  void dispose() {
    replayGain.dispose();
    transcoding.dispose();
  }
}
