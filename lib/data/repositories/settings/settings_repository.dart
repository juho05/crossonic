import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';

class SettingsRepository {
  final ReplayGainSettings replayGain;

  SettingsRepository({
    required KeyValueRepository keyValueRepository,
  }) : replayGain = ReplayGainSettings(
          keyValueRepository: keyValueRepository,
        );

  Future<void> load() async {
    await Future.wait([
      replayGain.load(),
    ]);
  }

  void dispose() {
    replayGain.dispose();
  }
}
