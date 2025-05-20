import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_player_method_channel.dart';

abstract class AudioPlayerPlatform extends PlatformInterface {
  /// Constructs a AudioPlayerPlatform.
  AudioPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioPlayerPlatform _instance = MethodChannelAudioPlayer();

  /// The default instance of [AudioPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioPlayer].
  static AudioPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioPlayerPlatform] when
  /// they register themselves.
  static set instance(AudioPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<void> get advanceStream;
  Stream<String> get stateStream;
  Stream<Duration> get restartStream;
  Stream<(Object, StackTrace)> get errorStream;

  Future<Duration> get position;
  Future<Duration> get bufferedPosition;
  Future<void> setVolume(double volume);

  Future<void> init();
  Future<void> setCurrent(Uri url, [Duration? pos]);
  Future<void> setNext(Uri? url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
