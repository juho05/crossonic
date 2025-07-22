import 'package:rxdart/rxdart.dart';

import 'audio_player_event.dart';
import 'audio_player_platform_interface.dart';

class AudioPlayerUnimplemented extends AudioPlayerPlatform {
  @override
  Future<Duration> get bufferedPosition => throw UnimplementedError();

  @override
  bool get canSeek => throw UnimplementedError();

  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }

  @override
  ValueStream<AudioPlayerEvent> get eventStream => throw UnimplementedError();

  @override
  Future<void> init() {
    throw UnimplementedError();
  }

  @override
  bool get initialized => throw UnimplementedError();

  @override
  Future<void> pause() {
    throw UnimplementedError();
  }

  @override
  Future<void> play() {
    throw UnimplementedError();
  }

  @override
  Future<Duration> get position => throw UnimplementedError();

  @override
  ValueStream<Duration> get restartPlayback => throw UnimplementedError();

  @override
  Future<void> seek(Duration position) {
    throw UnimplementedError();
  }

  @override
  Future<void> setCurrent(Uri url,
      {Uri? nextUrl, Duration pos = Duration.zero}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setNext(Uri? url) {
    throw UnimplementedError();
  }

  @override
  Future<void> setVolume(double volume) {
    throw UnimplementedError();
  }

  @override
  Future<void> stop() {
    throw UnimplementedError();
  }

  @override
  bool get supportsFileUri => throw UnimplementedError();

  @override
  double get volume => throw UnimplementedError();
}
