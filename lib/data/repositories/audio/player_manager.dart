/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:rxdart/rxdart.dart';

enum PlaybackStatus { stopped, loading, playing, paused }

class PlayerManager {
  final AudioPlayer _localPlayer;

  late AudioPlayer _player;

  final BehaviorSubject<PlaybackStatus> _playbackStatus =
      BehaviorSubject.seeded(PlaybackStatus.stopped);

  ValueStream<PlaybackStatus> get playbackStatus => _playbackStatus.stream;

  (DateTime time, Duration position) _positionUpdate = (
    DateTime.now(),
    Duration.zero,
  );

  Duration get position {
    if (_playbackStatus.value == PlaybackStatus.playing) {
      return _positionUpdate.$2 +
          (DateTime.now().difference(_positionUpdate.$1));
    }
    return _positionUpdate.$2;
  }

  final BehaviorSubject<Duration> _positionUpdateStream =
      BehaviorSubject.seeded(Duration.zero);

  ValueStream<Duration> get positionUpdateStream =>
      _positionUpdateStream.stream;

  Future<Duration> get bufferedPosition async => await _player.bufferedPosition;

  double _volume = 1;

  final BehaviorSubject<double> _volumeLinearStream = BehaviorSubject.seeded(1);

  ValueStream<double> get volumeLinearStream => _volumeLinearStream.stream;

  double get volumeLinear => _volume;

  set volumeLinear(double volume) {
    _volume = volume;
    _updatePlayerVolume();
    _volumeLinearStream.add(_volume);
  }

  double get volumeCubic => _volumeToCubic(_volume);

  set volumeCubic(double volume) {
    volumeLinear = _volumeToLinear(volume);
  }

  final StreamController<void> _advanceStream = StreamController.broadcast();

  Stream<void> get advance => _advanceStream.stream;

  final StreamController<Duration> _restartPlayback =
      StreamController.broadcast();

  Stream<Duration> get restartPlayback => _restartPlayback.stream;

  bool _playOnNextMediaChange = false;

  PlayerManager({required AudioPlayer localPlayer})
    : _localPlayer = localPlayer {
    changePlayer(_localPlayer);
  }

  StreamSubscription? _restartPlaybackSub;
  StreamSubscription? _playerEventsSub;
  StreamSubscription? _positionDiscontinuitySub;

  Future<void> changePlayer(AudioPlayer player) async {
    _restartPlaybackSub?.cancel();
    _playerEventsSub?.cancel();
    _positionDiscontinuitySub?.cancel();

    // TODO transfer playback
    _player = player;

    _restartPlaybackSub = _player.restartPlayback.listen(
      (event) => _restartPlayback.add(position),
    );
    _playerEventsSub = _player.eventStream.listen(
      (event) => _playerEvent(event),
    );
    _positionDiscontinuitySub = _player.positionDiscontinuity.listen(
      (pos) => _updatePosition(pos),
    );
  }

  Future<void> configureServerURL({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
    bool updateCurrentMediaItem = false,
  }) async {
    await _player.configureServerURL(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
      updateCurrentMediaItem: updateCurrentMediaItem,
    );
  }

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
    Log.trace("enabling playOnNextMediaChange");
  }

  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    await _player.setCurrent(current, next: next, pos: pos);
    if (_playOnNextMediaChange) {
      _playOnNextMediaChange = false;
      await _player.play();
    }
  }

  Future<void> setNext(Song? next) async {
    await _player.setNext(next);
  }

  Future<void> play() async {
    Log.trace("play");

    if (_playbackStatus.value == PlaybackStatus.playing) {
      return;
    }

    await _updatePlayerVolume();

    await _player.play();
  }

  Future<void> pause() async {
    Log.trace("pause");
    _playOnNextMediaChange = false;

    if (_playbackStatus.value == PlaybackStatus.paused) {
      return;
    }
    await _player.pause();
    _updatePlayerVolume();
  }

  Future<void> stop() async {
    if (_playbackStatus.value == PlaybackStatus.stopped) return;
    Log.trace("stop");
    _playOnNextMediaChange = false;
    _hasPlayed = false;
    _playbackStatus.add(PlaybackStatus.stopped);
    _updatePosition(Duration.zero);
    await _player.stop();
  }

  Duration? _seekingPos;

  Future<void> seek(Duration pos) async {
    Log.trace("seek to $pos");
    _seekingPos = pos;
    _updatePosition();
    await _player.seek(pos);
    _seekingPos = null;
  }

  Future<void> _updatePosition([Duration? pos]) async {
    if (_seekingPos != null) {
      pos = _seekingPos;
    }
    pos ??= await _player.position;
    Log.trace("updating current position: $pos");
    _positionUpdate = (DateTime.now(), pos);
    _positionUpdateStream.add(position);
  }

  bool _hasPlayed = false;

  AudioPlayerEvent? _previousAudioPlayerEvent;

  Future<void> _playerEvent(AudioPlayerEvent event) async {
    Log.trace("player event received: ${event.name}");
    if (event == AudioPlayerEvent.advance) {
      // prevent advance immediately after loading queue
      if (_hasPlayed) {
        await _updatePosition(Duration.zero);
        _advanceStream.add(null);
      }
      return;
    }

    if (_previousAudioPlayerEvent == event) return;

    Duration lastPos = _seekingPos ?? _positionUpdate.$2;
    if (_previousAudioPlayerEvent == AudioPlayerEvent.playing) {
      lastPos += DateTime.now().difference(_positionUpdate.$1);
    }

    _previousAudioPlayerEvent = event;

    var status = switch (event) {
      AudioPlayerEvent.stopped => PlaybackStatus.stopped,
      AudioPlayerEvent.loading => PlaybackStatus.loading,
      AudioPlayerEvent.playing => PlaybackStatus.playing,
      AudioPlayerEvent.paused => PlaybackStatus.paused,
      AudioPlayerEvent.advance => throw Exception("should never happen"),
    };

    Log.debug("new player status: $status");

    if (status == PlaybackStatus.stopped) {
      await stop();
      return;
    }

    _playbackStatus.add(status);

    if (status == PlaybackStatus.playing) {
      _hasPlayed = true;
      _updatePosition();
    } else {
      _updatePosition(lastPos);
    }
  }

  double _replayGainVolume = 1;

  Future<void> applyReplayGain(double gain) async {
    _replayGainVolume = gain;
    await _updatePlayerVolume();
  }

  Future<void> _updatePlayerVolume({double scalar = 1}) async {
    double volume = _volume * scalar;
    volume *= _replayGainVolume;
    await _player.setVolume(volume);
  }

  double _volumeToLinear(double volume) {
    return pow(volume, 3) as double;
  }

  double _volumeToCubic(double volume) {
    return pow(volume, 1 / 3.0) as double;
  }
}
