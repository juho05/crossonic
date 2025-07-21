import 'dart:math';

import 'package:audio_player_platform_interface/audio_player_event.dart';
import 'package:audio_player_platform_interface/audio_player_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerMediaKit extends AudioPlayerPlatform {
  Player? _player;

  static void registerWith([Object? _]) {
    AudioPlayerPlatform.instance = AudioPlayerMediaKit();
  }

  AudioPlayerMediaKit() {
    MediaKit.ensureInitialized();
  }

  @override
  Future<Duration> get position async =>
      _player?.state.position ?? Duration.zero;

  @override
  Future<Duration> get bufferedPosition async =>
      _player?.state.buffer ?? Duration.zero;

  final BehaviorSubject<AudioPlayerEvent> _eventStream = BehaviorSubject.seeded(
    AudioPlayerEvent.stopped,
  );

  @override
  ValueStream<AudioPlayerEvent> get eventStream => _eventStream.stream;

  Future<void> _onAdvance() async {
    _canSeek = _nextCanSeek;
    _nextCanSeek = false;
    _nextMedia = null;
    _eventStream.add(AudioPlayerEvent.advance);
  }

  bool _currentChanged = false;

  final BehaviorSubject<Duration> _restartPlayback = BehaviorSubject();
  @override
  ValueStream<Duration> get restartPlayback => _restartPlayback.stream;

  @override
  Future<void> pause() => _player!.pause();

  @override
  Future<void> play() => _player!.play();

  @override
  Future<void> seek(Duration position) => _player!.seek(position);

  Media? _nextMedia;

  @override
  Future<void> setCurrent(Uri url, [Duration? pos]) async {
    _canSeek = url.scheme == "file" ||
        (url.queryParameters.containsKey("format") &&
            url.queryParameters["format"] == "raw");
    _currentChanged = true;
    await _player!.open(
      Playlist([Media(url.toString()), if (_nextMedia != null) _nextMedia!]),
      play: _eventStream.value == AudioPlayerEvent.playing,
    );
    if (pos != null) {
      await seek(pos);
    }
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
    if (_player!.state.playlist.index <
        _player!.state.playlist.medias.length - 1) {
      await _player!.remove(_player!.state.playlist.medias.length - 1);
    }
    if (url == null) {
      _nextMedia = null;
      return;
    }
    _nextMedia = Media(url.toString());
    if (_player!.state.playlist.medias.isNotEmpty) {
      await _player!.add(_nextMedia!);
    }
  }

  @override
  Future<void> stop() async {
    if (!initialized) return;
    await _player!.stop();
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

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    _targetVolume = volume;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    if (!initialized) return;
    // mpv volume is cubic:
    // https://github.com/mpv-player/mpv/blob/440f35a26db3fd9f25282bff0f06f4e86e8133c2/player/audio.c#L177
    double volume = _targetVolume;
    if (!kIsWeb) {
      volume = pow(_targetVolume, 1.0 / 3).toDouble();
    }
    await _player!.setVolume(100 * volume);
  }

  @override
  bool get initialized => _player != null;

  @override
  Future<void> init() async {
    if (initialized) return;
    _player = Player(
      configuration: const PlayerConfiguration(title: "crossonic"),
    );
    _player!.stream.playing.listen((playing) {
      _onStateChange();
    });
    _player!.stream.buffering.listen((buffering) {
      _onStateChange();
    });

    int lastIndex = -1;
    _player!.stream.playlist.listen((playlist) {
      if (_currentChanged || lastIndex == playlist.index) {
        _currentChanged = false;
        lastIndex = playlist.index;
        return;
      }
      lastIndex = playlist.index;
      _onAdvance();
    });
    _player!.stream.completed.listen((completed) {
      if (!completed) return;
      if (_player!.state.playing) return;
      if (_player!.state.playlist.index + 1 ==
          _player!.state.playlist.medias.length) {
        // final advance to stop playback
        _onAdvance();
      }
    });
    _player!.stream.error.listen((err) => _onError(err));
    await _applyVolume();
  }

  Future<void> _onStateChange() async {
    if (_player!.state.buffering) {
      _eventStream.add(AudioPlayerEvent.loading);
      return;
    }
    if (_player!.state.playing) {
      _eventStream.add(AudioPlayerEvent.playing);
      return;
    }
    _eventStream.add(AudioPlayerEvent.paused);
  }

  @override
  Future<void> dispose() async {
    if (!initialized) return;
    final p = _player;
    _player = null;
    await p!.dispose();
  }

  Future<void> _onError(String msg) async {
    throw PlatformException(code: "media_kit:error", message: msg);
  }
}
