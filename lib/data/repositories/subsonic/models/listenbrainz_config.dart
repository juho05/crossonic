import 'package:crossonic/data/services/opensubsonic/models/listenbrainz_config_model.dart';

class ListenBrainzConfig {
  final String? username;

  ListenBrainzConfig({required this.username});

  factory ListenBrainzConfig.fromListenBrainzConfigModel(
      ListenBrainzConfigModel l) {
    return ListenBrainzConfig(
      username: l.listenBrainzUsername,
    );
  }
}
