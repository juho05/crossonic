import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'exoplayer_method_channel.dart';

abstract class ExoPlayerPlatform extends PlatformInterface {
  /// Constructs a AudioPlayerPlatform.
  ExoPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ExoPlayerPlatform _instance = MethodChannelExoPlayer();

  /// The default instance of [ExoPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelExoPlayer].
  static ExoPlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ExoPlayerPlatform] when
  /// they register themselves.
  static set instance(ExoPlayerPlatform instance) {
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
  Future<void> setCurrent(
    Uri url, {
    Uri? nextUrl,
    Duration pos = Duration.zero,
  });
  Future<void> setNext(Uri? url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();

  void ensureInitialized();
}
