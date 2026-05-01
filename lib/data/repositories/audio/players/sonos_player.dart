/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/sonos/sonos_device.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/upnp/upnp_connection.dart';
import 'package:crossonic/data/services/upnp/upnp_mediaitem.dart';
import 'package:crossonic/data/services/upnp/upnp_service.dart';
import 'package:crossonic/data/services/upnp/upnp_transport_info.dart';
import 'package:crossonic/utils/result.dart';

class SonosPlayer extends AudioPlayer {
  final UpnpService _upnp;
  final UpnpConnection _upnpCon;
  final SonosDevice _device;

  @override
  Device get device => _device;

  Duration _lastKnownPosition = Duration.zero;
  DateTime? _lastPositionRecordedAt;

  bool _setNextFailed = false;

  @override
  Future<Duration> get position async =>
      _lastKnownPosition +
      (_lastPositionRecordedAt != null &&
              eventStream.value == AudioPlayerEvent.playing
          ? DateTime.now().difference(_lastPositionRecordedAt!)
          : Duration.zero) +
      _positionOffset;

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  Duration _positionOffset = Duration.zero;

  @override
  // TODO
  Future<double> get volume async => 1;

  @override
  bool get supportsFilePlayback => false;

  SonosPlayer({
    required super.downloader,
    required UpnpService upnpService,
    required SonosDevice device,
  }) : _device = device,
       _upnp = upnpService,
       _upnpCon = UpnpConnection(
         ipAddr: device.ipAddr,
         avTransportControlUri: device.avTransportControlUri,
       ) {
    eventStream.listen((event) async {
      if (event == AudioPlayerEvent.advance) return;
      if (event == AudioPlayerEvent.playing) {
        _startPollingTimer();
      } else {
        _stopAdvanceTimer();
        _stopPollingTimer();
      }
    });
  }

  @override
  Future<void> configureServerURL({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
    bool updateCurrentMediaItem = false,
  }) async {
    super.configureServerURL(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      // TODO support transcoding
      format: "raw",
      maxBitRate: null,
      updateCurrentMediaItem: updateCurrentMediaItem,
    );
  }

  @override
  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    super.setCurrent(current, next: next, pos: pos);

    _setNextFailed = false;

    eventStream.add(AudioPlayerEvent.loading);

    _lastPositionRecordedAt = null;
    _lastKnownPosition = Duration.zero;
    _positionOffset = pos;
    positionDiscontinuity.add(pos);

    // TODO transcode incompatible media:
    // https://support.sonos.com/en-us/article/supported-audio-formats-for-sonos-music-library
    // https://docs.sonos.com/docs/supported-audio-formats
    // https://docs.sonos.com/docs/flac-best-practices

    Log.debug("set current set media item");
    final currentResult = await _upnp.setMediaItem(
      _upnpCon,
      UpnpMediaItem(
        url: constructStreamUri(current, pos: pos)!.toString(),
        duration: current.duration,
        transcoded: pos != Duration.zero,
        title: current.title,
        contentType: current.contentType ?? "audio/mpeg",
      ),
    );
    if (currentResult is Err) {
      Log.error("failed to set current media item", e: currentResult.error);
      return;
    }
    Log.debug("set current set media item done");

    await Future.delayed(const Duration(milliseconds: 500));

    final state = await _waitForTransportState({
      UpnpTransportState.pausedPlayback,
      UpnpTransportState.playing,
      UpnpTransportState.stopped,
    });
    _publishPlayerEvent(state);
    if (eventStream.value == AudioPlayerEvent.playing) {
      await _syncPosition();
    }

    final nextResult = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              duration: next.duration,
              transcoded: false,
              title: next.title,
              contentType: next.contentType ?? "audio/mpeg",
            )
          : null,
    );
    if (nextResult is Err) {
      Log.error("failed to set next media item", e: nextResult.error);
      _setNextFailed = true;
      return;
    }
    _setNextFailed = false;
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);

    final result = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              duration: next.duration,
              transcoded: false,
              title: next.title,
              contentType: next.contentType ?? "audio/mpeg",
            )
          : null,
    );
    if (result is Err) {
      Log.error("failed to set next media item", e: result.error);
      _setNextFailed = true;
      return;
    }
    _setNextFailed = false;
  }

  @override
  Future<void> play() async {
    if (eventStream.value == AudioPlayerEvent.playing) return;

    eventStream.add(AudioPlayerEvent.loading);

    final pos = await position;

    // unpausing is very unreliable and causes a variety of issues
    if (pos - _positionOffset == Duration.zero) {
      final result = await _upnp.play(_upnpCon);
      if (result is! Ok) {
        return;
      }

      final state = await _waitForTransportState({
        UpnpTransportState.playing,
        UpnpTransportState.stopped,
      });
      if (state == UpnpTransportState.playing) {
        _publishPlayerEvent(state);
        await _syncPosition();
        return;
      }
    }

    await setCurrent(currentSong.value!, next: nextSong.value, pos: pos);
    await play();
  }

  @override
  Future<void> pause() async {
    if (eventStream.value != AudioPlayerEvent.playing) return;
    _lastKnownPosition = await position;
    _lastPositionRecordedAt = null;

    eventStream.add(AudioPlayerEvent.loading);

    final result = await _upnp.pause(_upnpCon);

    final state = await _waitForTransportState({
      UpnpTransportState.pausedPlayback,
    });
    _publishPlayerEvent(state);
  }

  @override
  Future<void> stop() async {
    if (eventStream.value == AudioPlayerEvent.stopped) return;
    eventStream.add(AudioPlayerEvent.loading);

    final result = await _upnp.stop(_upnpCon);

    await _waitForTransportState({UpnpTransportState.stopped});

    if (result is Ok) {
      eventStream.add(AudioPlayerEvent.stopped);
      _lastKnownPosition = Duration.zero;
      _lastPositionRecordedAt = null;
      _positionOffset = Duration.zero;
    }
  }

  @override
  Future<void> seek(Duration pos) async {
    final shouldPlay = eventStream.value == AudioPlayerEvent.playing;
    _stopAdvanceTimer();
    Log.debug("seek to: $pos");
    await setCurrent(currentSong.value!, next: nextSong.value, pos: pos);
    Log.debug("seek set current done");
    if (shouldPlay) {
      await play();
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    // TODO
  }

  Future<UpnpTransportState?> _waitForTransportState(
    Set<UpnpTransportState> state, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      final result = await _upnp.getTransportInfo(_upnpCon);
      if (result is Err) {
        Log.error(
          "Failed to wait for upnp transport state",
          e: (result as Err).error,
        );
        return null;
      }
      final info = result.tryValue!;
      Log.debug("transport state wait current: ${info.state.name}");
      if (state.contains(info.state)) {
        return info.state;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  void _publishPlayerEvent(UpnpTransportState? state) {
    final event = switch (state) {
      UpnpTransportState.playing => AudioPlayerEvent.playing,
      UpnpTransportState.pausedPlayback ||
      UpnpTransportState.stopped => AudioPlayerEvent.paused,
      UpnpTransportState.transitioning ||
      UpnpTransportState.unknown ||
      null => AudioPlayerEvent.loading,
    };
    if (event != eventStream.value) {
      eventStream.add(event);
    }
  }

  Timer? _advanceTimer;

  void _setAdvanceTimer(Duration remainingDuration) {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(
      Duration(milliseconds: max(remainingDuration.inMilliseconds, 1)),
      () async {
        _advanceTimer = null;
        await _advance();
      },
    );
  }

  void _stopAdvanceTimer() {
    _advanceTimer?.cancel();
    _advanceTimer = null;
  }

  Future<void> _advance() async {
    _positionOffset = Duration.zero;
    _lastPositionRecordedAt = null;
    _lastKnownPosition = Duration.zero;
    positionDiscontinuity.add(await position);

    if (nextSong.value == null) {
      await stop();
      return;
    }

    final next = nextSong.value!;

    if (!_setNextFailed) {
      _startPollingTimer(resetRunning: true);

      final state = await _waitForTransportState({
        UpnpTransportState.playing,
        UpnpTransportState.stopped,
      });
      if (state != UpnpTransportState.stopped) {
        eventStream.add(AudioPlayerEvent.advance);
        return;
      }
    }

    eventStream.add(AudioPlayerEvent.advance);

    await setCurrent(next, next: null);
    await play();
  }

  Timer? _pollingTimer;

  void _startPollingTimer({bool resetRunning = false}) {
    if (_pollingTimer != null && !resetRunning) return;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _syncState();
    });
  }

  void _stopPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _syncState() async {
    final result = await _upnp.getTransportInfo(_upnpCon);
    if (result is Err) {
      Log.error("Failed to get upnp transport state", e: (result as Err).error);
      return;
    }
    _publishPlayerEvent(result.tryValue!.state);
    if (eventStream.value == AudioPlayerEvent.playing) {
      await _syncPosition();
    }
  }

  Future<void> _syncPosition() async {
    final result = await _upnp.getPositionInfo(_upnpCon);
    switch (result) {
      case Err():
        Log.error("Failed to sync sonos position", e: result.error);
      case Ok():
    }
    Log.debug(
      "position info: ${result.tryValue!.pos} at ${result.tryValue!.approximateTime}",
    );
    _lastKnownPosition = result.tryValue!.pos;
    _lastPositionRecordedAt = result.tryValue!.approximateTime;
    positionDiscontinuity.add(await position);

    if (currentSong.value?.duration != null) {
      _setAdvanceTimer(currentSong.value!.duration! - result.tryValue!.pos);
    }
  }
}
