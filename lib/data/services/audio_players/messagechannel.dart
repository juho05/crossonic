import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

// TODO configure audio session
class AudioPlayerMessageChannel implements AudioPlayer {
  static const _channel =
      MethodChannel("crossonic.julianh.de/audioplayer/messages");
  static const _events =
      EventChannel("crossonic.julianh.de/audioplayer/events");

  AudioPlayerMessageChannel(AudioSession audioSession) {
    _events
        .receiveBroadcastStream()
        .doOnError(_onPlatformError)
        .listen(_onPlatformEvent);
  }

  @override
  Future<Duration> get position async => Duration(
      milliseconds: await _channel.invokeMethod<int>("getPosition") ?? 0);

  @override
  Future<Duration> get bufferedPosition async => Duration(
      milliseconds:
          await _channel.invokeMethod<int>("getBufferedPosition") ?? 0);

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);

  @override
  ValueStream<AudioPlayerEvent> get eventStream => _eventStream.stream;

  Future<void> _onAdvance() async {
    _canSeek = _nextCanSeek;
    _nextCanSeek = false;
    _eventStream.add(AudioPlayerEvent.advance);
  }

  Future<void> _onStateChange(String platformState) async {
    final state = AudioPlayerEvent.values.byName(platformState);
    if (state == eventStream.value) return;
    switch (state) {
      case AudioPlayerEvent.stopped:
        await stop();
      case AudioPlayerEvent.loading:
        _eventStream.add(AudioPlayerEvent.loading);
      case AudioPlayerEvent.paused:
        _eventStream.add(AudioPlayerEvent.paused);
      case AudioPlayerEvent.playing:
        _eventStream.add(AudioPlayerEvent.playing);
      case AudioPlayerEvent.advance:
        break;
    }
  }

  @override
  Future<void> pause() async {
    await _channel.invokeMethod("pause");
  }

  @override
  Future<void> play() async {
    await _channel.invokeMethod("play");
  }

  @override
  Future<void> seek(Duration position) async {
    await _channel.invokeMethod("seek", {"pos": position.inMilliseconds});
  }

  @override
  Future<void> setCurrent(Uri url, [Duration? pos]) async {
    _canSeek = url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
    await _channel.invokeMethod(
        "setCurrent", {"uri": url.toString(), "pos": pos?.inMilliseconds ?? 0});
  }

  @override
  Future<void> setNext(Uri? url) async {
    if (url != null) {
      _nextCanSeek = url.scheme == "file" ||
          (url.queryParameters.containsKey("format") &&
              url.queryParameters["format"] == "raw");
    } else {
      _nextCanSeek = false;
    }
    if (!initialized) {
      return;
    }
    await _channel.invokeMethod("setNext", {"uri": url.toString()});
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod("play");
  }

  @override
  bool get supportsFileUri => true;

  bool _canSeek = false;
  bool _nextCanSeek = false;
  @override
  bool get canSeek => _canSeek;

  double _volume = 1;

  @override
  double get volume => _volume;

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    await _channel.invokeMethod("setVolume", {"volume": volume});
    _volume = volume;
  }

  bool _initialized = false;
  @override
  bool get initialized => _initialized;

  @override
  Future<void> init() async {
    if (initialized) return;
    await _channel.invokeMethod("init");
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!initialized) return;
    await _channel.invokeMethod("dispose");
    _initialized = false;
  }

  Future<void> _onPlatformEvent(dynamic event) async {
    final eventObj = event as Map<Object?, dynamic>;
    switch (eventObj["name"]) {
      case "advance":
        await _onAdvance();
      case "state":
        await _onStateChange(
            (eventObj["data"] as Map<Object?, dynamic>)["state"] as String);
    }
  }

  Future<void> _onPlatformError(Object error, StackTrace stackTrace) async {
    if (error is! PlatformException) {
      Log.error("MessageChannel Player Exception", error, stackTrace);
      return;
    }
    final platformError = error;
    Log.error(
        "MessageChannel Player: ${platformError.code}: ${platformError.message}",
        platformError,
        stackTrace);
  }
}
