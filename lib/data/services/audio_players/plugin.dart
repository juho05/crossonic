import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_player/audio_player.dart' as plugin;

class AudioPlayerPlugin implements AudioPlayer {
  final AudioSession _audioSession;

  final plugin.AudioPlayer _player;

  AudioPlayerPlugin(AudioSession audioSession)
      : _audioSession = audioSession,
        _player = plugin.AudioPlayer() {
    _player.advanceStream.listen((_) => _onAdvance());
    _player.stateStream.listen((state) => _onStateChange(state));
    _player.errorStream.listen((err) => _onPlatformError(err.$1, err.$2));
    _player.restartStream.listen((pos) {
      _restartPlayback.add(pos);
    });

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
  Future<Duration> get position async => _player.position;

  @override
  Future<Duration> get bufferedPosition async => _player.bufferedPosition;

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
        _eventStream.add(AudioPlayerEvent.stopped);
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

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> setCurrent(Uri url, [Duration? pos]) async {
    _canSeek = url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
    await _player.setCurrent(url, pos);
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
    await _player.setNext(url);
  }

  @override
  Future<void> stop() async {
    if (!initialized) return;
    await _player.stop();
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
      await _player.setVolume(volume * 0.5);
    } else {
      await _player.setVolume(volume);
    }
  }

  bool _initialized = false;
  @override
  bool get initialized => _initialized;

  @override
  Future<void> init() async {
    if (initialized) return;
    await _player.init();
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!initialized) return;
    await _player.dispose();
    _initialized = false;
    await _audioSession.setActive(false);
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
