import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

import 'audio_player_event.dart';
import 'audio_player_unimplemented.dart';

abstract class AudioPlayerPlatform extends PlatformInterface {
  AudioPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioPlayerPlatform _instance = AudioPlayerUnimplemented();

  static AudioPlayerPlatform get instance => _instance;

  static set instance(AudioPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  ValueStream<AudioPlayerEvent> get eventStream => _instance.eventStream;
  ValueStream<Duration> get restartPlayback => _instance.restartPlayback;
  Future<Duration> get position => _instance.position;
  Future<Duration> get bufferedPosition => _instance.bufferedPosition;
  bool get supportsFileUri => _instance.supportsFileUri;
  bool get canSeek => _instance.canSeek;
  bool get needsManualFade => _instance.needsManualFade;
  double get volume => _instance.volume;
  Future<void> setVolume(double volume) => _instance.setVolume(volume);
  bool get initialized => _instance.initialized;

  Future<void> init() => _instance.init();
  Future<void> setCurrent(Uri url,
          {Uri? nextUrl, Duration pos = Duration.zero}) =>
      _instance.setCurrent(url, nextUrl: nextUrl, pos: pos);
  Future<void> setNext(Uri? url) => _instance.setNext(url);
  Future<void> play() => _instance.play();
  Future<void> pause() => _instance.pause();
  Future<void> stop() => _instance.stop();
  Future<void> seek(Duration position) => _instance.seek(position);
  Future<void> dispose() => _instance.dispose();
}
