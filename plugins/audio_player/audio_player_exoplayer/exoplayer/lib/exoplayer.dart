import 'exoplayer_platform_interface.dart';

class ExoPlayer {
  Stream<void> get advanceStream => ExoPlayerPlatform.instance.advanceStream;
  Stream<String> get stateStream => ExoPlayerPlatform.instance.stateStream;
  Stream<Duration> get restartStream =>
      ExoPlayerPlatform.instance.restartStream;
  Stream<(Object, StackTrace)> get errorStream =>
      ExoPlayerPlatform.instance.errorStream;

  Future<Duration> get position => ExoPlayerPlatform.instance.position;
  Future<Duration> get bufferedPosition =>
      ExoPlayerPlatform.instance.bufferedPosition;
  Future<void> setVolume(double volume) =>
      ExoPlayerPlatform.instance.setVolume(volume);

  Future<void> init() => ExoPlayerPlatform.instance.init();
  Future<void> setCurrent(Uri url, [Duration? pos]) =>
      ExoPlayerPlatform.instance.setCurrent(url, pos);
  Future<void> setNext(Uri? url) => ExoPlayerPlatform.instance.setNext(url);
  Future<void> play() => ExoPlayerPlatform.instance.play();
  Future<void> pause() => ExoPlayerPlatform.instance.pause();
  Future<void> stop() => ExoPlayerPlatform.instance.stop();
  Future<void> seek(Duration position) =>
      ExoPlayerPlatform.instance.seek(position);
  Future<void> dispose() => ExoPlayerPlatform.instance.dispose();

  void ensureInitialized() => ExoPlayerPlatform.instance.ensureInitialized();
}
