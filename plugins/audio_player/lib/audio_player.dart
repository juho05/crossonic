import 'audio_player_platform_interface.dart';

class AudioPlayer {
  Stream<void> get advanceStream => AudioPlayerPlatform.instance.advanceStream;
  Stream<String> get stateStream => AudioPlayerPlatform.instance.stateStream;
  Stream<Duration> get restartStream =>
      AudioPlayerPlatform.instance.restartStream;
  Stream<(Object, StackTrace)> get errorStream =>
      AudioPlayerPlatform.instance.errorStream;

  Future<Duration> get position => AudioPlayerPlatform.instance.position;
  Future<Duration> get bufferedPosition =>
      AudioPlayerPlatform.instance.bufferedPosition;
  Future<void> setVolume(double volume) =>
      AudioPlayerPlatform.instance.setVolume(volume);

  Future<void> init() => AudioPlayerPlatform.instance.init();
  Future<void> setCurrent(Uri url, [Duration? pos]) =>
      AudioPlayerPlatform.instance.setCurrent(url, pos);
  Future<void> setNext(Uri? url) => AudioPlayerPlatform.instance.setNext(url);
  Future<void> play() => AudioPlayerPlatform.instance.play();
  Future<void> pause() => AudioPlayerPlatform.instance.pause();
  Future<void> stop() => AudioPlayerPlatform.instance.stop();
  Future<void> seek(Duration position) =>
      AudioPlayerPlatform.instance.seek(position);
  Future<void> dispose() => AudioPlayerPlatform.instance.dispose();
}
