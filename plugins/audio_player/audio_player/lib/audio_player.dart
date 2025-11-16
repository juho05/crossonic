import 'package:audio_player_platform_interface/audio_player_event.dart';
import 'package:audio_player_platform_interface/audio_player_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

export 'package:audio_player_platform_interface/audio_player_event.dart';

class AudioPlayer {
  AudioPlayerPlatform get _platform => AudioPlayerPlatform.instance;

  ValueStream<AudioPlayerEvent> get eventStream => _platform.eventStream;
  ValueStream<Duration> get restartPlayback => _platform.restartPlayback;
  Future<Duration> get position => _platform.position;
  Future<Duration> get bufferedPosition => _platform.bufferedPosition;
  bool get supportsFileUri => _platform.supportsFileUri;
  bool get canSeek => _platform.canSeek;
  bool get needsManualFade => _platform.needsManualFade;
  double get volume => _platform.volume;
  Future<void> setVolume(double volume) => _platform.setVolume(volume);
  bool get initialized => _platform.initialized;

  Future<void> init() => _platform.init();
  Future<void> setCurrent(Uri url,
          {required Uri? nextUrl, Duration pos = Duration.zero}) =>
      _platform.setCurrent(url, nextUrl: nextUrl, pos: pos);
  Future<void> setNext(Uri? url) => _platform.setNext(url);
  Future<void> play() => _platform.play();
  Future<void> pause() => _platform.pause();
  Future<void> stop() => _platform.stop();
  Future<void> seek(Duration position) => _platform.seek(position);
  Future<void> dispose() => _platform.dispose();
}
