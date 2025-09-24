import 'package:crossonic/data/services/opensubsonic/models/listenbrainz_config_model.dart';

class ListenBrainzConfig {
  final String? username;
  final bool scrobble;
  final bool syncFeedback;

  ListenBrainzConfig(
      {required this.username,
      required this.scrobble,
      required this.syncFeedback});

  factory ListenBrainzConfig.fromListenBrainzConfigModel(
      ListenBrainzConfigModel l) {
    return ListenBrainzConfig(
        username: l.listenBrainzUsername,
        scrobble: l.scrobble ?? false,
        syncFeedback: l.syncFeedback ?? false);
  }
}
