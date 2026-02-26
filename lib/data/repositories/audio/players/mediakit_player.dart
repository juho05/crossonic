import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

class AudioPlayerMediaKit extends AudioPlayer {
  final MediaIntegration _integration;
  final SettingsRepository _settings;

  late final AudioSession _audioSession;
  StreamSubscription? _audioSessionInterruptionStream;
  StreamSubscription? _audioSessionBecomingNoisyStream;

  Player? _player;

  AudioPlayerMediaKit({
    required super.downloader,
    required SettingsRepository settings,
    required MediaIntegration integration,
    required super.setVolumeHandler,
    required super.setQueueHandler,
    required super.setLoopHandler,
    required super.playNextHandler,
    required super.playPrevHandler,
  }) : _integration = integration,
       _settings = settings {
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

  @override
  Future<void> init({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
  }) async {
    await super.init(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
    );
    await _setupAudioSession();
    _player = Player(
      configuration: const PlayerConfiguration(title: "crossonic"),
    );
    _player!.stream.playing.listen((playing) => _onStateChange());
    _player!.stream.buffering.listen((buffering) => _onStateChange());
    int lastIndex = -1;
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
    await _integration.ensureInitialized(
      onPlay: play,
      onPause: pause,
      onSeek: seek,
      onPlayNext: playNextHandler,
      onPlayPrev: playPrevHandler,
      onStop: () async {
        if (_settings.workarounds.stopIsPause) {
          await pause();
          return;
        }
        await stop();
      },
      onVolumeChanged: (volume) async {
        await setVolumeHandler(pow(volume, 3) as double);
      },
      onReplaceQueue: setQueueHandler,
      onLoopChanged: setLoopHandler,
    );
    currentSong.addListener(() {
      _integration.updateMedia(
        currentSong.value,
        constructCoverUri(currentSong.value),
      );
    });
    eventStream.listen((value) async {
      if (value == AudioPlayerEvent.advance) return;
      _integration.updatePlaybackState(switch (value) {
        AudioPlayerEvent.stopped => PlaybackStatus.stopped,
        AudioPlayerEvent.loading => PlaybackStatus.loading,
        AudioPlayerEvent.playing => PlaybackStatus.playing,
        AudioPlayerEvent.paused => PlaybackStatus.paused,
        AudioPlayerEvent.advance => throw Exception("not reachable"),
      });
    });
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

  @override
  Future<void> pause() async {
    // TODO implement fade
    await _player?.pause();
  }

  @override
  Future<void> play() async {
    _shouldUnpauseOnInterruptionEnd = false;
    if (!await _audioSession.setActive(true)) {
      if (_player?.state.playing ?? false) {
        await _player?.pause();
      }
      return;
    }
    await _player!.play();
  }

  @override
  Future<void> seek(Duration position) async {
    if (currentSong.value == null) return;
    if (canSeek) {
      await _player!.seek(position);
      positionDiscontinuity.add(position);
      return;
    }
    await setCurrent(currentSong.value!, next: nextSong.value, pos: position);
    positionDiscontinuity.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    volume = volume.clamp(0, 1);
    _targetVolume = volume;
    await _applyVolume();
  }

  Future<void> _applyVolume() async {
    // mpv volume is cubic:
    // https://github.com/mpv-player/mpv/blob/440f35a26db3fd9f25282bff0f06f4e86e8133c2/player/audio.c#L177
    double volume = _targetVolume;
    if (!kIsWeb) {
      volume = pow(_targetVolume, 1.0 / 3).toDouble();
    }
    if (_ducking) {
      volume *= 0.5;
    }
    await _player!.setVolume(100 * volume);
  }

  @override
  Future<void> stop() async {
    _integration.updateMedia(null, null);
    _nextDebounce?.cancel();
    _ducking = false;
    _shouldUnpauseOnInterruptionEnd = false;
    await _player!.stop();
    await _audioSession.setActive(false);
    eventStream.add(AudioPlayerEvent.stopped);
  }

  @override
  Future<void> dispose() async {
    _nextDebounce?.cancel();
    _audioSessionBecomingNoisyStream?.cancel();
    _audioSessionInterruptionStream?.cancel();
    _integration.updateMedia(null, null);
    await _player?.dispose();
    await super.dispose();
  }

  Future<void> _onError(String msg) async {
    throw PlatformException(code: "media_kit:error", message: msg);
  }
}
