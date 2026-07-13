/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/device_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/players/android_player.dart';
import 'package:crossonic/data/repositories/audio/players/sonos_player.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/prefetch/queue_prefetcher.dart';
import 'package:crossonic/data/repositories/settings/replay_gain.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:flutter/foundation.dart';

class PlaybackManager {
  final AuthRepository _auth;
  final SettingsRepository _settings;
  final SubsonicRepository _subsonic;
  final MethodChannelService _methodChannel;

  final PlayerManager _player;

  PlayerManager get player => _player;

  final QueueManager _queue;

  QueueManager get queue => _queue;

  final DeviceManager _deviceManager;

  DeviceManager get deviceManager => _deviceManager;

  (TranscodingCodec, int) _transcoding;

  final MediaIntegration _integration;

  final QueuePrefetcher _prefetcher;

  PlaybackManager({
    required QueueManager queueManager,
    required PlayerManager playerManager,
    required this._deviceManager,
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required SubsonicRepository subsonicRepository,
    required this._integration,
    required this._methodChannel,
    required QueuePrefetcher queuePrefetcher,
  }) : _queue = queueManager,
       _player = playerManager,
       _auth = authRepository,
       _settings = settingsRepository,
       _subsonic = subsonicRepository,
       _transcoding = (
         settingsRepository.transcoding.codec,
         settingsRepository.transcoding.maxBitRate,
       ),
       _prefetcher = queuePrefetcher {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();

    _queue.currentAndNext.listen(_onCurrentOrNextChanged);

    _settings.transcoding.addListener(_onTranscodingChanged);
    _settings.replayGain.addListener(_applyReplayGain);
    _settings.prefetch.addListener(_refreshPrefetchState);

    _prefetcher.songCached.listen(_onSongCached);
    _prefetcher.songRemovedFromCache.listen(_onSongRemovedFromCache);
    _refreshPrefetchState();

    _integration.ensureInitialized(
      onPlay: _player.play,
      onPause: _player.pause,
      onLoopChanged: _queue.setLoop,
      onPlayNext: playNext,
      onPlayPrev: playPrev,
      onSeek: _player.seek,
      onStop: _player.stop,
      onVolumeChanged: (volume) async => _player.volumeLinear = volume,
      onVolumeUp: () async => _stepVolume(_volumeKeyStep),
      onVolumeDown: () async => _stepVolume(-_volumeKeyStep),
    );

    _queue.looping.listen((loop) {
      _integration.updateLoop(loop);
    });

    _queue.current.listen((current) {
      _applyReplayGain();
      _integration.updateMedia(
        current,
        current != null
            ? _subsonic.getCoverUri(
                current.coverId,
                constantSalt: true,
                size: 512,
              )
            : null,
      );
    });

    _player.advance.listen((_) async {
      await _queue.advance();
    });

    _player.positionUpdateStream.listen((pos) {
      _integration.updatePosition(pos);
    });

    PlaybackStatus previousPlaybackStatus = PlaybackStatus.stopped;
    _player.playbackStatus.listen((status) async {
      if (status == previousPlaybackStatus) return;
      previousPlaybackStatus = status;
      if (status == PlaybackStatus.stopped) {
        await _queue.clear();
      }
      _integration.updatePlaybackState(status);
    });

    _player.restartPlayback.listen(
      (pos) => _restartPlayback(
        pos,
        play: _player.playbackStatus.value == PlaybackStatus.playing,
      ),
    );
  }

  static const double _volumeKeyStep = 0.03;

  final StreamController<void> _volumeKeyEvents = StreamController.broadcast();

  Stream<void> get volumeKeyEvents => _volumeKeyEvents.stream;

  Throttle1<double>? _volumeKeyThrottle;
  double? _volumeKeyTarget;
  Timer? _volumeKeyResync;

  void _stepVolume(double delta) {
    _volumeKeyThrottle ??= Throttle1(
      action: (v) => _player.volumeCubic = v,
      delay: const Duration(milliseconds: 150),
      leading: true,
      trailing: true,
    );
    _volumeKeyTarget = ((_volumeKeyTarget ?? _player.volumeCubic) + delta)
        .clamp(0.0, 1.0);
    _volumeKeyThrottle!.call(_volumeKeyTarget!);
    _volumeKeyEvents.add(null);

    _volumeKeyResync?.cancel();
    _volumeKeyResync = Timer(
      const Duration(milliseconds: 500),
      () => _volumeKeyTarget = null,
    );
  }

  Future<void> changeDevice(Device device) async {
    final player = await deviceManager.createPlayerFromDevice(device);

    _player.cancelPlayerStreams();

    final play = _player.playbackStatus.value == PlaybackStatus.playing;
    final pos = _player.position;

    try {
      if (!kIsWeb && Platform.isAndroid) {
        if (player is AudioPlayerAndroid || player == null) {
          Log.debug("enabling android player");
          await _methodChannel.invokeMethod("setPlayerEnabled", {
            "enabled": true,
          });
        } else {
          Log.debug("disabling android player");
          await _methodChannel.invokeMethod("setPlayerEnabled", {
            "enabled": false,
          });
        }

        await _methodChannel.invokeMethod("setInterceptVolumeKeys", {
          "enabled": player is SonosPlayer,
        });
      }

      await _player.changePlayer(player);
      await _configurePlayerServerURL();

      final next = _queue.currentAndNext.value.next;
      if (_queue.current.value != null) {
        await _player.setCurrent(_queue.current.value!, next: next, pos: pos);
      }
    } finally {
      _player.connectPlayerStreams();
      await _applyReplayGain();
      _refreshPrefetchState();
    }

    Log.debug("player: $player");

    if (play) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  Future<void> playNext() async {
    Log.trace("play next");
    if (!_queue.canAdvance) {
      Log.warn("ignoring play next request because there is no next song");
      return;
    }
    await _queue.skipNext();
  }

  Future<void> playPrev() async {
    Log.trace("play prev");
    if (_player.position.inSeconds > 3 || !_queue.canGoBack) {
      if (!_queue.canGoBack) {
        Log.trace(
          "seeking back to beginning of current song because there is no previous song",
        );
      } else {
        Log.trace(
          "seeking back to beginning of current song because the current position is >3 s into the song: ${_player.position.inSeconds}",
        );
      }
      await _player.seek(Duration.zero);
      return;
    }
    Log.trace("going back one song in the queue");
    await _queue.skipPrev();
  }

  Future<void> _onCurrentOrNextChanged(
    ({Song? current, Song? next, bool currentChanged, bool fromAdvance}) event,
  ) async {
    if (event.current == null) {
      Log.trace("current song changed to null, calling stop...");
      await _player.stop();
      return;
    }
    if (event.currentChanged) {
      Log.trace(
        "current song changed: ${event.current?.id}, from advance: ${event.fromAdvance}",
      );
    }

    if (event.currentChanged && !event.fromAdvance) {
      await _player.setCurrent(event.current!, next: event.next);
    } else {
      Log.trace("next song changed: ${event.next?.id}");
      await _player.setNext(event.next);
    }
  }

  bool? _wasAuthenticated;

  Future<void> _onAuthChanged() async {
    if (_auth.isAuthenticated) {
      if (_wasAuthenticated == false) {
        await _queue.init();
      }
      _wasAuthenticated = true;
      await _configurePlayerServerURL();
      return;
    }
    _wasAuthenticated = false;

    Log.debug("ensuring player is stopped because user logged out");
    await player.stop();

    await _configurePlayerServerURL();
  }

  Future<void> _onTranscodingChanged() async {
    if (!_auth.isAuthenticated) return;
    _transcoding = await _settings.transcoding.activeTranscoding();
    Log.debug(
      "current active transcoding profile: ${_transcoding.$1.name}${_transcoding.$1 != TranscodingCodec.raw ? "${_transcoding.$2} kbps" : ""}",
    );
    await _configurePlayerServerURL();
  }

  Future<void> _applyReplayGain() async {
    ReplayGainMode mode = _settings.replayGain.mode;
    final media = _queue.current.value;
    if (mode == ReplayGainMode.disabled || media == null) {
      await _player.applyReplayGain(1);
      return;
    }

    Log.trace("applying replay gain, mode: ${mode.name}");

    double gain = _settings.replayGain.fallbackGain;

    if (mode == ReplayGainMode.auto) {
      mode = ReplayGainMode.track;

      if (media.album != null) {
        bool previousIsSameAlbum = true;
        if (_queue.currentIndex > 0) {
          final previous = (await _queue.getRegularSongs(
            limit: 1,
            offset: _queue.currentIndex - 1,
          )).first;
          previousIsSameAlbum = previous.album?.id == media.album!.id;
        }

        final next = _queue.currentAndNext.value.next;
        bool nextIsSameAlbum =
            next == null || next.album?.id == media.album!.id;

        if (previousIsSameAlbum && nextIsSameAlbum && _queue.length > 1) {
          mode = ReplayGainMode.album;
        }
      }
    }

    if (media.trackGain != null &&
        (mode == ReplayGainMode.track || media.albumGain == null)) {
      gain = media.trackGain!;
    } else if (media.albumGain != null) {
      gain = media.albumGain!;
    } else if (_settings.replayGain.preferServerFallbackGain) {
      gain = media.fallbackGain ?? gain;
      Log.warn(
        "using fallback gain because ${_queue.current.value?.id} has no replay gain metadata",
      );
    }

    double volume = pow(10, gain / 20) as double;
    Log.debug("replay gain of current song: $gain dB -> $volume");

    await _player.applyReplayGain(volume);
  }

  static const Duration _prefetchBufferThreshold = Duration(seconds: 3);

  Timer? _prefetchMonitor;
  Timer? _prefetchThrottleTimer;

  void _refreshPrefetchState() {
    if (_player.supportsFilePlayback && _settings.prefetch.enabled) {
      _prefetcher.enable();
      _startPrefetchMonitor();
    } else {
      _prefetcher.disable();
      _stopPrefetchMonitor();
      _prefetcher.setThrottled(false);
    }
  }

  void _startPrefetchMonitor() {
    _prefetchMonitor ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => _evaluatePrefetchPressure(),
    );
  }

  void _stopPrefetchMonitor() {
    _prefetchMonitor?.cancel();
    _prefetchMonitor = null;
    _prefetchThrottleTimer?.cancel();
    _prefetchThrottleTimer = null;
  }

  Future<void> _evaluatePrefetchPressure() async {
    final status = _player.playbackStatus.value;
    if (status == PlaybackStatus.stopped ||
        status == PlaybackStatus.paused ||
        _player.playingLocalFile) {
      _unthrottlePrefetch();
      return;
    }

    final buffered = await _player.bufferedPosition;
    final position = _player.position;
    final ahead = buffered - position;

    final duration = _queue.current.value?.duration;
    final fullyBuffered =
        // ignore if duration is unknown
        duration == null ||
        // buffered position might be negative if duration is unknown to native player
        buffered < Duration.zero ||
        buffered >= duration - const Duration(seconds: 1);

    final healthy =
        status != PlaybackStatus.loading &&
        (position < const Duration(seconds: 3) ||
            ahead >= _prefetchBufferThreshold ||
            fullyBuffered);

    if (healthy) {
      _unthrottlePrefetch();
    } else {
      Log.debug(
        "prefetch pressure: status=${status.name} pos=$position "
        "buffered=$buffered ahead=$ahead duration=$duration",
      );
      _prefetchThrottleTimer ??= Timer(const Duration(seconds: 1), () {
        _prefetchThrottleTimer = null;
        _prefetcher.setThrottled(true);
      });
    }
  }

  void _unthrottlePrefetch() {
    _prefetchThrottleTimer?.cancel();
    _prefetchThrottleTimer = null;
    _prefetcher.setThrottled(false);
  }

  void _onSongCached(Song song) {
    if (!_player.supportsFilePlayback) return;
    final next = _queue.currentAndNext.value.next;
    if (next == null || next.id != song.id) return;

    final duration = _queue.current.value?.duration;
    if (duration != null &&
        duration - _player.position <= const Duration(seconds: 10)) {
      return;
    }

    Log.debug("prefetched next song ${next.id} ready, re-setting next");
    _player.setNext(next);
  }

  void _onSongRemovedFromCache(String id) {
    if (!_player.supportsFilePlayback) return;
    final next = _queue.currentAndNext.value.next;
    if (next?.id != id) return;

    Log.debug(
      "prefetched next song $id removed from cache, re-setting next to network url",
    );
    _player.setNext(next);
  }

  Future<void> _configurePlayerServerURL() async {
    if (_auth.isAuthenticated) {
      await _player.configureServerURL(
        streamUri: _createStreamUri(),
        coverUri: _createCoverUri(),
        supportsTimeOffset: _subsonic.supports.transcodeOffset,
        supportsTimeOffsetMs: _subsonic.supports.timeOffsetMs,
        format: _transcoding.$1 != TranscodingCodec.serverDefault
            ? _transcoding.$1.name
            : null,
        maxBitRate: _transcoding.$1 != TranscodingCodec.raw
            ? _transcoding.$2
            : null,
        updateCurrentMediaItem: false,
      );
    } else {
      await _player.configureServerURL(
        streamUri: Uri(),
        coverUri: Uri(),
        supportsTimeOffset: false,
        supportsTimeOffsetMs: false,
        maxBitRate: null,
        format: null,
      );
    }
  }

  Future<void> _restartPlayback(Duration pos, {bool play = true}) async {
    if (_queue.current.value == null) return;
    Log.debug(
      "Restarting playback at position $pos, play after restore: $play",
    );

    final songDuration = _queue.current.value!.duration;

    await _applyReplayGain();

    if (songDuration != null &&
        songDuration - pos < const Duration(seconds: 1)) {
      Log.debug(
        "Target position of restart playback is at end of song, skipping to next song instead",
      );
      await playNext();
      if (play) {
        await _player.play();
      }
      return;
    }

    final next = _queue.currentAndNext.value.next;
    await _player.setCurrent(_queue.current.value!, next: next, pos: pos);

    if (play) {
      await _player.play();
    } else {
      await _player.pause();
    }
  }

  Uri _createStreamUri() {
    if (!_auth.isAuthenticated) return Uri();
    return Uri.parse(
      '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: _subsonic.generateQuery(const {}, _auth.con.auth))}',
    );
  }

  Uri _createCoverUri() {
    if (!_auth.isAuthenticated) return Uri();
    return Uri.parse(
      '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: _subsonic.generateQuery(const {}, _auth.con.auth))}',
    );
  }
}
