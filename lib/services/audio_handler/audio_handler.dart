import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:crossonic/services/audio_handler/offline_cache/offline_cache.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:crossonic/services/audio_handler/media_queue.dart';
import 'package:crossonic/services/audio_handler/integrations/integration.dart';
import 'package:crossonic/components/cover_art.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum CrossonicPlaybackStatus {
  stopped,
  loading,
  playing,
  paused,
}

class CrossonicPlaybackState extends Equatable {
  final CrossonicPlaybackStatus status;
  final Duration position;
  final Duration bufferedPosition;

  const CrossonicPlaybackState({
    required this.status,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
  });

  CrossonicPlaybackState copyWith({
    CrossonicPlaybackStatus? status,
    Duration? position,
    Duration? bufferedPosition,
  }) =>
      CrossonicPlaybackState(
        status: status ?? this.status,
        position: position ?? this.position,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      );

  @override
  List<Object?> get props => [status, position, bufferedPosition];
}

class CrossonicAudioHandler {
  final MediaQueue _queue = MediaQueue();
  MediaQueue get mediaQueue => _queue;
  final BehaviorSubject<CrossonicPlaybackState> _playbackState =
      BehaviorSubject.seeded(const CrossonicPlaybackState(
          status: CrossonicPlaybackStatus.stopped));
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus =>
      _playbackState;

  final CrossonicAudioPlayer _player;
  bool _playerLoaded = false;

  final APIRepository _apiRepository;
  final NativeIntegration _integration;
  final Settings _settings;

  StreamSubscription? _playerEventStream;

  bool _playOnNextMediaChange = false;
  Timer? _positionTimer;

  final OfflineCache _offlineCache;

  TranscodeSetting _currentTranscode =
      const TranscodeSetting(format: null, maxBitRate: null);
  TranscodeSetting _nextTranscode =
      const TranscodeSetting(format: null, maxBitRate: null);
  Duration _positionOffset = Duration.zero;

  CrossonicAudioHandler({
    required APIRepository apiRepository,
    required CrossonicAudioPlayer player,
    required NativeIntegration integration,
    required Settings settings,
    required OfflineCache offlineCache,
  })  : _apiRepository = apiRepository,
        _player = player,
        _integration = integration,
        _settings = settings,
        _offlineCache = offlineCache {
    _apiRepository.authStatus.listen((status) async {
      if (status != AuthStatus.authenticated) {
        await stop();
      }
    });
    _integration.ensureInitialized(
      audioHandler: this,
      onPause: pause,
      onPlay: play,
      onPlayNext: skipToNext,
      onPlayPrev: skipToPrevious,
      onSeek: seek,
      onStop: stop,
    );
    _integration.updateMedia(null, null);

    _settings.transcodeSetting.listen((transcode) async {
      final next = _queue.current.value?.next;
      if (next != null && _nextTranscode != transcode) {
        _player.setNext(
            next,
            await _getStreamURL(
              songID: next.id,
              transcode: transcode,
            ));
        _nextTranscode = transcode;
      }
    });

    _settings.replayGain.listen((_) async {
      await _applyReplayGain();
    });

    _queue.current.listen(_mediaChanged);

    _playerEventStream = _player.eventStream.listen(_playerEvent);
  }

  Future<void> _ensurePlayerLoaded([bool restorePlayerState = true]) async {
    if (_playerLoaded) return;
    print("initializing player...");
    _player.init();
    _playerLoaded = true;
    _applyReplayGain();
    if (restorePlayerState) {
      await _restorePlayerState();
    }
  }

  Future<void> _restorePlayerState() async {
    print("restoring player state...");
    final media = _queue.current.value;
    _positionOffset = Duration.zero;
    if (media != null) {
      await _player.setCurrent(
        media.item,
        await _getStreamURL(
          songID: media.item.id,
          timeOffset: _playbackState.value.position.inSeconds,
          transcode: _currentTranscode,
        ),
      );
      _positionOffset = _playbackState.value.position;
      if (_playbackState.value.status == CrossonicPlaybackStatus.playing) {
        await play();
      } else {
        await pause();
      }
      _nextTranscode = await _settings.getTranscodeSettings();
      if (media.next != null) {
        await _player.setNext(
            media.next,
            await _getStreamURL(
              songID: media.next!.id,
              transcode: _nextTranscode,
            ));
      } else {
        await _player.setNext(null, null);
      }
    } else {
      await stop();
    }
  }

  Future<void> _disposePlayer() async {
    if (!_playerLoaded ||
        _playbackState.value.status == CrossonicPlaybackStatus.playing ||
        _playbackState.value.status == CrossonicPlaybackStatus.loading) {
      return;
    }
    _playerLoaded = false;
    print("disposing player...");
    await _player.dispose();
  }

  Timer? _disposePlayerTimeout;
  void _playerEvent(AudioPlayerEvent event) {
    if (!_playerLoaded) return;
    if (event == AudioPlayerEvent.advance) {
      _queue.advance();
      return;
    }
    var status = switch (event) {
      AudioPlayerEvent.stopped => CrossonicPlaybackStatus.stopped,
      AudioPlayerEvent.loading => CrossonicPlaybackStatus.loading,
      AudioPlayerEvent.playing => CrossonicPlaybackStatus.playing,
      AudioPlayerEvent.paused => CrossonicPlaybackStatus.paused,
      AudioPlayerEvent.advance => throw Exception("should never happen"),
    };
    if (_queue.length == 0) {
      status = CrossonicPlaybackStatus.stopped;
    }
    if (status != _playbackState.value.status) {
      if (status == CrossonicPlaybackStatus.stopped) {
        stop();
      } else {
        _integration.updatePlaybackState(status);
        _playbackState.add(_playbackState.value.copyWith(
          status: status,
        ));
        _updatePosition(true);
        if (status == CrossonicPlaybackStatus.playing) {
          _startPositionTimer();
        } else {
          _stopPositionTimer();
        }

        if (status != CrossonicPlaybackStatus.playing &&
            status != CrossonicPlaybackStatus.loading) {
          // web browsers stop media os integration without active player
          if (!kIsWeb) {
            _disposePlayerTimeout ??=
                Timer(const Duration(minutes: 3), _disposePlayer);
          }
        } else {
          _disposePlayerTimeout?.cancel();
          _disposePlayerTimeout = null;
        }
      }
    }
  }

  Future<void> _mediaChanged(CurrentMedia? media) async {
    CrossonicPlaybackStatus status = _playbackState.value.status;
    var playAfterChange = _playOnNextMediaChange;
    if (media == null) {
      _integration.updateMedia(null, null);
    } else if (media.currentChanged) {
      _integration.updateMedia(
        media.item,
        media.item.coverArt != null
            ? _apiRepository.getCoverArtURL(
                coverArtID: media.item.coverArt!,
                size: const CoverResolution.large().size)
            : null,
      );
    }
    if (media == null) {
      _playOnNextMediaChange = false;
      if (status != CrossonicPlaybackStatus.stopped) {
        await stop();
      }
      return;
    }

    await _ensurePlayerLoaded(false);

    if (media.currentChanged) {
      _applyReplayGain();

      _playOnNextMediaChange = false;
      if (!media.fromNext) {
        _currentTranscode = await _settings.getTranscodeSettings();
        await _player.setCurrent(
            media.item,
            await _getStreamURL(
              songID: media.item.id,
              transcode: _currentTranscode,
            ));
      } else {
        _currentTranscode = _nextTranscode;
      }
      _positionOffset = Duration.zero;
      _playbackState.add(_playbackState.value.copyWith(
        position: Duration.zero,
        bufferedPosition: Duration.zero,
      ));
      _integration.updatePosition(Duration.zero, Duration.zero);
      if (status == CrossonicPlaybackStatus.playing || playAfterChange) {
        await play();
      } else {
        await pause();
      }
    } else {
      _updatePosition(true);
    }

    _nextTranscode = await _settings.getTranscodeSettings();
    if (media.next != null) {
      await _player.setNext(
          media.next,
          await _getStreamURL(
            songID: media.next!.id,
            transcode: _nextTranscode,
          ));
    } else {
      await _player.setNext(null, null);
    }
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    int counter = 0;
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!kIsWeb && Platform.isLinux) {
        counter++;
      }
      _updatePosition(counter % 5 == 0);
    });
  }

  Future<void> _updatePosition(bool updateNative) async {
    if (_playbackState.value.status == CrossonicPlaybackStatus.stopped) {
      _playbackState.add(_playbackState.value.copyWith(
        position: Duration.zero,
      ));
      if (updateNative) {
        _integration.updatePosition(Duration.zero);
      }
      return;
    }
    if (_playbackState.value.status != CrossonicPlaybackStatus.playing &&
        _playbackState.value.status != CrossonicPlaybackStatus.paused) {
      return;
    }

    await _ensurePlayerLoaded();

    final pos = await _player.position;
    final bufferedPos = await _player.bufferedPosition;
    _playbackState.add(_playbackState.value.copyWith(
      position: pos + _positionOffset,
      bufferedPosition: bufferedPos + _positionOffset,
    ));
    if (updateNative) {
      _integration.updatePosition(
          pos + _positionOffset, bufferedPos + _positionOffset);
    }
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Future<void> playPause() async {
    if (!crossonicPlaybackStatus.hasValue) return;
    if (crossonicPlaybackStatus.value.status ==
        CrossonicPlaybackStatus.playing) {
      return await pause();
    }
    if (mediaQueue.current.valueOrNull == null) return;
    return await play();
  }

  Future<void> play() async {
    if (_queue.current.valueOrNull == null) return;
    await _ensurePlayerLoaded();
    await _player.play();
  }

  Future<void> pause() async {
    await _ensurePlayerLoaded();
    await _player.pause();
  }

  Future<void> stop() async {
    _playbackState.add(
        const CrossonicPlaybackState(status: CrossonicPlaybackStatus.stopped));
    _integration.updateMedia(null, null);
    _integration.updatePosition(Duration.zero);
    _integration.updatePlaybackState(CrossonicPlaybackStatus.stopped);
    await _disposePlayer();
    _queue.clear();
  }

  Future<void> seek(Duration position) async {
    final media = _queue.current.valueOrNull?.item;
    await _ensurePlayerLoaded();
    if (media == null) return;
    if (_player.canSeek && _positionOffset == Duration.zero) {
      await _player.seek(position);
    } else {
      position = Duration(seconds: position.inSeconds);
      _currentTranscode = await _settings.getTranscodeSettings();
      await _player.setCurrent(
          media,
          await _getStreamURL(
            songID: media.id,
            timeOffset: position.inSeconds,
            transcode: _currentTranscode,
          ));
      _positionOffset = position;
    }
    _playbackState.add(_playbackState.value
        .copyWith(position: position, bufferedPosition: position));
  }

  Future<void> skipToNext() async {
    if (_queue.canAdvance) {
      _queue.advance(false);
    }
  }

  Future<void> skipToPrevious() async {
    if (_playbackState.value.position.inSeconds > 3 || !_queue.canGoBack) {
      await seek(Duration.zero);
      return;
    }
    if (_queue.canGoBack) {
      _queue.back();
    }
  }

  Future<void> dispose() async {
    _playerEventStream?.cancel();
    await _player.dispose();
  }

  Future<void> _applyReplayGain() async {
    if (!_playerLoaded) return;
    ReplayGainMode mode = _settings.replayGain.value.mode;
    if (mode == ReplayGainMode.disabled) {
      if (_player.volume < 1) {
        print("replay gain disabled, settings volume to 1");
        _player.setVolume(1);
      }
      return;
    }
    final media = _queue.current.value?.item;
    if (media == null) return;

    double gain = _settings.replayGain.value.fallbackGain;

    if (mode == ReplayGainMode.auto) {
      mode = ReplayGainMode.track;

      if (media.albumId != null) {
        bool previousIsSameAlbum = true;
        if (_queue.current.value!.index > 0) {
          final previous = _queue.queue[_queue.current.value!.index - 1];
          previousIsSameAlbum = previous.albumId == media.albumId;
        }

        final next = _queue.current.value!.next;
        bool nextIsSameAlbum = next == null || next.albumId == media.albumId;

        if (previousIsSameAlbum && nextIsSameAlbum && _queue.length > 1) {
          mode = ReplayGainMode.album;
        }
      }
    }

    String gainMode = "local fallback";
    if ((mode == ReplayGainMode.track && media.replayGain?.trackGain != null) ||
        media.replayGain?.albumGain == null) {
      gain = media.replayGain!.trackGain!;
      gainMode = "track";
    } else if (media.replayGain?.albumGain != null) {
      gain = media.replayGain!.albumGain!;
      gainMode = "album";
    } else if (_settings.replayGain.value.preferServerFallback) {
      gain = media.replayGain?.fallbackGain ?? gain;
      gainMode = "server fallback";
    }

    double volume = pow(10, gain / 20) as double;
    print("applying $gainMode gain: $gain dB -> volume: $volume...");
    await _player.setVolume(volume);
  }

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }

  Future<Uri> _getStreamURL({
    required String songID,
    required TranscodeSetting transcode,
    int? timeOffset,
  }) async {
    if ((timeOffset ?? 0) == 0) {
      final url = await _offlineCache.getURL(songID);
      if (url != null) {
        return url;
      }
    }
    return _apiRepository.getStreamURL(
      songID: songID,
      format: transcode.format,
      maxBitRate: transcode.maxBitRate,
      timeOffset: timeOffset,
    );
  }

  bool get supportsLocalPlayback => _player.supportsFileURLs;
}
