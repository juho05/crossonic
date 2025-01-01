import 'package:crossonic/repositories/api/models/models.dart';
import 'package:rxdart/rxdart.dart';

enum AudioPlayerEvent {
  advance,
  stopped,
  loading,
  playing,
  paused,
}

abstract interface class CrossonicAudioPlayer {
  BehaviorSubject<AudioPlayerEvent> get eventStream;
  Future<Duration> get position;
  Future<Duration> get bufferedPosition;
  bool get supportsFileURLs;
  bool get canSeek;
  double get volume;
  Future<void> setVolume(double volume);

  void init();
  Future<void> setCurrent(Media media, Uri url);
  Future<void> setNext(Media? media, Uri? url);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
