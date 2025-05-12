import 'package:rxdart/rxdart.dart';

enum AudioPlayerEvent {
  advance,
  stopped,
  loading,
  playing,
  paused,
}

abstract interface class AudioPlayer {
  ValueStream<AudioPlayerEvent> get eventStream;
  ValueStream<Duration> get restartPlayback;
  Future<Duration> get position;
  Future<Duration> get bufferedPosition;
  bool get supportsFileUri;
  bool get canSeek;
  double get volume;
  Future<void> setVolume(double volume);
  bool get initialized;

  Future<void> init();
  Future<void> setCurrent(Uri url, [Duration? pos]);
  Future<void> setNext(Uri? url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
