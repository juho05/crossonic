/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

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
  DateTime? _lastPositionRecordedAt = null;

  @override
  Future<Duration> get position async =>
      _lastKnownPosition +
      (_lastPositionRecordedAt != null &&
              eventStream.value == AudioPlayerEvent.playing
          ? DateTime.now().difference(_lastPositionRecordedAt!)
          : Duration.zero);

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  @override
  // TODO
  Future<double> get volume async => 1;

  @override
  bool get supportsFilePlayback => false;

  // TODO setup event streams and publish events
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
      if (event == AudioPlayerEvent.advance) {
        _lastPositionRecordedAt = null;
        _lastKnownPosition = Duration.zero;
        await _syncState();
        return;
      }
      if (event == AudioPlayerEvent.playing) {
        _startPollingTimer();
      } else {
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

    eventStream.add(AudioPlayerEvent.loading);

    _lastPositionRecordedAt = null;
    _lastKnownPosition = Duration.zero;

    // TODO transcode incompatible media:
    // https://support.sonos.com/en-us/article/supported-audio-formats-for-sonos-music-library
    // https://docs.sonos.com/docs/supported-audio-formats
    // https://docs.sonos.com/docs/flac-best-practices

    final currentResult = await _upnp.setMediaItem(
      _upnpCon,
      UpnpMediaItem(
        url: constructStreamUri(current, pos: pos)!.toString(),
        // TODO investigate what effect a wrong content type has
        contentType: current.contentType ?? "audio/mpeg",
        duration: current.duration,
        // TODO change depending on whether transcoding is used
        seekable: true,
        title: current.title,
      ),
    );

    final nextResult = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              contentType: next.contentType ?? "audio/mpeg",
              duration: next.duration,
              seekable: true,
              title: next.title,
            )
          : null,
    );

    final state = await _waitForTransportState({
      UpnpTransportState.pausedPlayback,
      UpnpTransportState.playing,
      UpnpTransportState.stopped,
    });
    _publishPlayerEvent(state);
    if (eventStream.value == AudioPlayerEvent.playing) {
      await _syncPosition();
    }
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);

    final result = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              contentType: next.contentType ?? "audio/mpeg",
              duration: next.duration,
              seekable: true,
              title: next.title,
            )
          : null,
    );
  }

  @override
  Future<void> play() async {
    if (eventStream.value == AudioPlayerEvent.playing) return;
    eventStream.add(AudioPlayerEvent.loading);

    final pos = await position;

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
      // TODO replace with proper events from SONOS
      eventStream.add(AudioPlayerEvent.stopped);
      _lastKnownPosition = Duration.zero;
      _lastPositionRecordedAt = null;
    }
  }

  @override
  Future<void> seek(Duration position) async {
    // TODO
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

  Timer? _pollingTimer;

  void _startPollingTimer() {
    if (_pollingTimer != null) return;
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
    Log.debug("position info: ${result.tryValue}");
    _lastKnownPosition = result.tryValue!.pos;
    _lastPositionRecordedAt = result.tryValue!.approximateTime;
    positionDiscontinuity.add(await position);
  }
}
