import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

export 'audioservice.dart';
export 'smtc_stub.dart' if (dart.library.ffi) 'smtc.dart';

abstract interface class MediaIntegration {
  Future<void> ensureInitialized({
    required AudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  });
  void updateMedia(Song? song, Uri? coverArt);
  void updatePosition(Duration position);
  void updatePlaybackState(PlaybackStatus status);
}
