import 'package:rxdart/rxdart.dart';

enum AudioPlayerEvent {
  advance,
  stopped,
  loading,
  playing,
  paused,
}

abstract interface class AudioPlayer {
  BehaviorSubject<AudioPlayerEvent> get eventStream;
  Future<Duration> get position;
  Future<Duration> get bufferedPosition;
  bool get supportsFileUri;
  bool get canSeek;
  double get volume;
  Future<void> setVolume(double volume);
  bool get initialized;

  void init();
  Future<void> setCurrent(Uri url);
  Future<void> setNext(Uri? url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
