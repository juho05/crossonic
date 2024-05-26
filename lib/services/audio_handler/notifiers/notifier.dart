import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';

export 'audioservice.dart';
export 'smtc_stub.dart' if (dart.library.ffi) 'smtc.dart';

abstract interface class NativeNotifier {
  void ensureInitialized({
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  });
  void updateMedia(Media? media, Uri? coverArt);
  void updatePosition(Duration position, [Duration bufferedPosition]);
  void updatePlaybackState(CrossonicPlaybackStatus status);
}
