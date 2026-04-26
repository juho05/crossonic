/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/sonos/sonos_device.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/upnp/upnp_connection.dart';
import 'package:crossonic/data/services/upnp/upnp_mediaitem.dart';
import 'package:crossonic/data/services/upnp/upnp_service.dart';

class SonosPlayer extends AudioPlayer {
  final UpnpService _upnp;
  final UpnpConnection _upnpCon;
  final SonosDevice _device;

  @override
  Device get device => _device;

  @override
  // TODO
  Future<Duration> get position async => Duration.zero;

  @override
  // TODO
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
       );

  Future<void> testConnection() async {
    // TODO
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

    if (eventStream.value == AudioPlayerEvent.stopped) {
      eventStream.add(AudioPlayerEvent.paused);
    }

    final currentResult = await _upnp.setMediaItem(
      _upnpCon,
      UpnpMediaItem(
        url: constructStreamUri(current, pos: pos)!.toString(),
        // TODO set to the correct value
        contentType: "audio/mpeg",
        duration: current.duration,
        seekable: false,
        title: current.title,
      ),
    );

    final nextResult = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              // TODO set to the correct value
              contentType: "audio/mpeg",
              duration: next.duration,
              seekable: false,
              title: next.title,
            )
          : null,
    );
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);

    final result = await _upnp.setNextMediaItem(
      _upnpCon,
      next != null
          ? UpnpMediaItem(
              url: constructStreamUri(next)!.toString(),
              // TODO set to the correct value
              contentType: "audio/mpeg",
              duration: next.duration,
              seekable: false,
              title: next.title,
            )
          : null,
    );
  }

  @override
  Future<void> play() async {
    if (eventStream.value == AudioPlayerEvent.playing) return;
    final result = await _upnp.play(_upnpCon);

    // TODO replace with proper events from SONOS
    eventStream.add(AudioPlayerEvent.playing);
  }

  @override
  Future<void> pause() async {
    if (eventStream.value != AudioPlayerEvent.playing) return;
    final result = await _upnp.pause(_upnpCon);

    // TODO replace with proper events from SONOS
    eventStream.add(AudioPlayerEvent.paused);
  }

  @override
  Future<void> stop() async {
    if (eventStream.value == AudioPlayerEvent.stopped) return;
    final result = await _upnp.stop(_upnpCon);

    // TODO replace with proper events from SONOS
    eventStream.add(AudioPlayerEvent.stopped);
  }

  @override
  Future<void> seek(Duration position) async {
    // TODO
  }

  @override
  Future<void> setVolume(double volume) async {
    // TODO
  }
}
