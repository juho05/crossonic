/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/audio/players/mediakit_setproperty.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

class AudioPlayerMediaKit extends AudioPlayer {
  late final AudioSession _audioSession;
  StreamSubscription? _audioSessionInterruptionStream;
  StreamSubscription? _audioSessionBecomingNoisyStream;

  Player? _player;

  AudioPlayerMediaKit({
    required super.downloader,
    required MediaIntegration integration,
  }) {
    MediaKit.ensureInitialized();
  }

  Duration _positionOffset = Duration.zero;

  @override
  Future<Duration> get position async =>
      (_player?.state.position ?? Duration.zero) + _positionOffset;

  @override
  Future<Duration> get bufferedPosition async =>
      _player?.state.buffer ?? Duration.zero + _positionOffset;

  double _targetVolume = 1;

  @override
  Future<double> get volume async => _targetVolume;

  bool _currentChanged = false;

  Future<void> init() async {
    await _setupAudioSession();
    _player = Player(
      configuration: const PlayerConfiguration(title: "crossonic"),
    );
    await setMPVProperty(_player!, "audio-client-name", "Crossonic");
    await setMPVProperty(_player!, "gapless-audio", "weak");
    await setMPVProperty(_player!, "prefetch-playlist", "yes");
    _player!.stream.playing.listen((playing) => _onStateChange());
    _player!.stream.buffering.listen((buffering) => _onStateChange());
    int lastIndex = 0;
    _player!.stream.playlist.listen((playlist) async {
      if (_currentChanged || lastIndex == playlist.index) {
        _currentChanged = false;
        lastIndex = playlist.index;
        return;
      }
      lastIndex = playlist.index;
      _positionOffset = Duration.zero;
      positionDiscontinuity.add(await position);
      eventStream.add(AudioPlayerEvent.advance);
    });
    _player!.stream.completed.listen((completed) async {
      if (!completed) return;
      if (_player!.state.playing) return;
      if (_player!.state.playlist.index + 1 ==
          _player!.state.playlist.medias.length) {
        // final advance to stop playback
        _positionOffset = Duration.zero;
        positionDiscontinuity.add(await position);
        eventStream.add(AudioPlayerEvent.advance);
      }
    });
    _player!.stream.error.listen((err) => _onError(err));
    await _applyVolume();
  }

  bool _ducking = false;
  bool _shouldUnpauseOnInterruptionEnd = false;

  Future<void> _setupAudioSession() async {
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(const AudioSessionConfiguration.music());

    _audioSessionInterruptionStream = _audioSession.interruptionEventStream
        .listen((event) async {
          if (event.begin) {
            switch (event.type) {
              case AudioInterruptionType.duck:
                Log.debug(
                  "received volume duck begin request from audio_session",
                );
                _ducking = true;
                await _applyVolume();
                break;
              case AudioInterruptionType.pause:
                Log.debug("received pause begin request from audio_session");
                _shouldUnpauseOnInterruptionEnd =
                    _player?.state.playing ?? false;
                await pause();
                break;
              case AudioInterruptionType.unknown:
                Log.debug("received unknown begin request from audio_session");
                _shouldUnpauseOnInterruptionEnd =
                    _player?.state.playing ?? false;
                await pause();
                break;
            }
          } else {
            switch (event.type) {
              case AudioInterruptionType.duck:
                Log.debug(
                  "received volume duck end request from audio_session",
                );
                _ducking = false;
                await _applyVolume();
                break;
              case AudioInterruptionType.pause:
                Log.debug("received pause begin end from audio_session");
                if (_shouldUnpauseOnInterruptionEnd) await play();
                break;
              case AudioInterruptionType.unknown:
                Log.debug("received unknown end request from audio_session");
                if (_shouldUnpauseOnInterruptionEnd) await play();
                break;
            }
            _shouldUnpauseOnInterruptionEnd = false;
          }
        });

    _audioSessionBecomingNoisyStream = _audioSession.becomingNoisyEventStream
        .listen((_) async {
          Log.debug("received becoming noisy event from audio_session");
          _shouldUnpauseOnInterruptionEnd = false;
          await pause();
        });
  }

  Future<void> _onStateChange() async {
    if (_player!.state.buffering) {
      eventStream.add(AudioPlayerEvent.loading);
      return;
    }
    if (_player!.state.playing) {
      _shouldUnpauseOnInterruptionEnd = false;
      eventStream.add(AudioPlayerEvent.playing);
      return;
    }
    if (eventStream.value != AudioPlayerEvent.stopped) {
      eventStream.add(AudioPlayerEvent.paused);
    }
  }

  @override
  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    await super.setCurrent(current, next: next, pos: pos);
    final currentUrl = constructStreamUri(current, pos: !canSeek ? pos : null);
    final nextUrl = constructStreamUri(next);
    _positionOffset = !canSeek ? pos : Duration.zero;
    _currentChanged = true;
    await _player!.open(
      Playlist([
        Media(
          currentUrl.toString(),
          start: canSeek && pos > Duration.zero ? pos : null,
        ),
        if (next != null) Media(nextUrl.toString()),
      ]),
      play: eventStream.value == AudioPlayerEvent.playing,
    );
    positionDiscontinuity.add(pos);
  }

  Timer? _nextDebounce;

  @override
  Future<void> setNext(Song? next) async {
    _nextDebounce?.cancel();
    _nextDebounce = Timer(const Duration(milliseconds: 100), () async {
      await super.setNext(next);
      if (_player!.state.playlist.index <
          _player!.state.playlist.medias.length - 1) {
        try {
          await _player!.remove(_player!.state.playlist.medias.length - 1);
        } catch (e) {
          rethrow;
        }
      }
      final url = constructStreamUri(next);
      if (url != null) {
        await _player!.add(Media(url.toString()));
      }
    });
    await super.setNext(next);
  }

  Timer? _pauseFadeTimer;

  @override
  Future<void> pause() async {
    if (!(_player?.state.playing ?? false)) return;
    _pauseFadeTimer?.cancel();
    double volume = _targetVolume;
    final stepSize = (volume / 100) * 5;
    _pauseFadeTimer = Timer.periodic(const Duration(milliseconds: 5), (
      timer,
    ) async {
      volume -= stepSize;
      if (volume <= 0) {
        _pauseFadeTimer?.cancel();
        _pauseFadeTimer = null;
        await _player!.pause();
        await _applyVolume();
        positionDiscontinuity.add(await position);
        return;
      }
      await _player?.setVolume(_calculatePlayerVolume(volume));
    });
    eventStream.add(AudioPlayerEvent.paused);
  }

  @override
  Future<void> play() async {
    _shouldUnpauseOnInterruptionEnd = false;
    _pauseFadeTimer?.cancel();
    if (!await _audioSession.setActive(true)) {
      if (_player?.state.playing ?? false) {
        await _player?.pause();
      }
      return;
    }
    await _player!.play();
  }

  @override
  Future<void> seek(Duration pos) async {
    if (currentSong.value == null) return;
    if (canSeek) {
      await _player!.seek(pos);
      positionDiscontinuity.add(pos);
      return;
    }
    await setCurrent(currentSong.value!, next: nextSong.value, pos: pos);
    positionDiscontinuity.add(pos);
  }

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    _targetVolume = volume;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    await _player!.setVolume(_calculatePlayerVolume(_targetVolume));
  }

  double _calculatePlayerVolume(double targetVolume) {
    // mpv volume is cubic:
    // https://github.com/mpv-player/mpv/blob/440f35a26db3fd9f25282bff0f06f4e86e8133c2/player/audio.c#L177
    if (!kIsWeb) {
      targetVolume = pow(targetVolume, 1.0 / 3).toDouble();
    }
    if (_ducking) {
      targetVolume *= 0.5;
    }
    return targetVolume * 100;
  }

  @override
  Future<void> stop() async {
    _nextDebounce?.cancel();
    _ducking = false;
    _shouldUnpauseOnInterruptionEnd = false;
    _pauseFadeTimer?.cancel();
    await _player!.stop();
    await _audioSession.setActive(false);
    eventStream.add(AudioPlayerEvent.stopped);
  }

  @override
  Future<void> dispose() async {
    _nextDebounce?.cancel();
    _audioSessionBecomingNoisyStream?.cancel();
    _audioSessionInterruptionStream?.cancel();
    _pauseFadeTimer?.cancel();
    await _player?.dispose();
    await super.dispose();
  }

  Future<void> _onError(String msg) async {
    throw PlatformException(code: "media_kit:error", message: msg);
  }
}
