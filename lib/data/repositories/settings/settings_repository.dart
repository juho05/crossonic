import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';

class SettingsRepository {
  final ReplayGainSettings replayGain;
  final TranscodingSettings transcoding;

  SettingsRepository({
    required KeyValueRepository keyValueRepository,
    required SubsonicRepository subsonic,
  })  : replayGain = ReplayGainSettings(
          keyValueRepository: keyValueRepository,
        ),
        transcoding = TranscodingSettings(
          keyValueRepository: keyValueRepository,
          subsonicRepository: subsonic,
        );

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
