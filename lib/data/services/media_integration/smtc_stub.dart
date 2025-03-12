import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';

class SMTCIntegration implements MediaIntegration {
  @override
  Future<void> ensureInitialized({
    required AudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) async {}
  @override
  void updateMedia(Song? song, Uri? coverArt) {}
  @override
  void updatePlaybackState(PlaybackStatus status) {}
  @override
  void updatePosition(Duration position,
      [Duration bufferedPosition = Duration.zero]) {}
}
