import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/services/audio_handler/integrations/integration.dart';

class SMTCIntegration implements NativeIntegration {
  @override
  void ensureInitialized({
    required CrossonicAudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) {}
  @override
  void updateMedia(Media? media, Uri? coverArt) {}
  @override
  void updatePlaybackState(CrossonicPlaybackStatus status) {}
  @override
  void updatePosition(Duration position,
      [Duration bufferedPosition = Duration.zero]) {}
}
