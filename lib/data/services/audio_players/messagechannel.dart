import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerMessageChannel implements AudioPlayer {
  static const _channel =
      MethodChannel("crossonic.julianh.de/audioplayer/messages");
  static const _events =
      EventChannel("crossonic.julianh.de/audioplayer/events");

  final AudioSession _audioSession;

  AudioPlayerMessageChannel(AudioSession audioSession)
      : _audioSession = audioSession {
    _events
        .receiveBroadcastStream()
        .doOnError(_onPlatformError)
        .listen(_onPlatformEvent);

    _audioSession.interruptionEventStream.listen((event) async {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _ducking = true;
            _applyVolume();
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _ducking = false;
            _applyVolume();
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            await play();
            break;
        }
      }
    });

    _audioSession.becomingNoisyEventStream.listen((_) async {
      await pause();
    });
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
    await _audioSession.setActive(state == AudioPlayerEvent.playing);
  }

  final BehaviorSubject<Duration> _restartPlayback = BehaviorSubject();
  @override
  ValueStream<Duration> get restartPlayback => _restartPlayback.stream;

  Future<void> _onRestart(int millis) async {
    _restartPlayback.add(Duration(milliseconds: millis));
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
    if (!initialized) return;
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

  @override
  double get volume => _targetVolume;

  double _targetVolume = 1;
  bool _ducking = false;

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    _targetVolume = volume;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    if (_ducking) {
      await _channel.invokeMethod("setVolume", {"volume": volume * 0.5});
    } else {
      await _channel.invokeMethod("setVolume", {"volume": volume});
    }
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
    await _audioSession.setActive(false);
  }

  Future<void> _onPlatformEvent(dynamic event) async {
    final eventObj = event as Map<Object?, dynamic>;
    final data = eventObj["data"] as Map<Object?, dynamic>?;
    switch (eventObj["name"]) {
      case "advance":
        await _onAdvance();
      case "state":
        await _onStateChange(data!["state"] as String);
      case "restart":
        await _onRestart(data!["pos"] as int);
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
