/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/methodchannel/android_mediaitem.dart';
import 'package:crossonic/data/services/methodchannel/method_channel_service.dart';

class AudioPlayerAndroid extends AudioPlayer {
  final CoverRepository _coverRepo;
  final SettingsRepository _settings;
  final MethodChannelService _methodChannel;

  AudioPlayerAndroid({
    required MethodChannelService methodChannel,
    required CoverRepository coverRepository,
    required SettingsRepository settings,
    required super.downloader,
    required super.setVolumeHandler,
    required super.setQueueHandler,
    required super.setLoopHandler,
    required super.playNextHandler,
    required super.playPrevHandler,
    required super.restartPlayback,
  }) : _methodChannel = methodChannel,
       _coverRepo = coverRepository,
       _settings = settings;

  @override
  Future<Duration> get position async =>
      Duration(milliseconds: await _methodChannel.invokeMethod("getPosition"));

  @override
  Future<Duration> get bufferedPosition async => Duration(
    milliseconds: await _methodChannel.invokeMethod("getBufferedPosition"),
  );

  @override
  Future<double> get volume async =>
      await _methodChannel.invokeMethod("getVolume");

  DateTime? _initTime;
  @override
  Future<void> init({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
  }) async {
    _initTime = DateTime.now();
    await super.init(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
    );
    _settings.workarounds.addListener(_onWorkaroundsChanged);
    _methodChannel.addEventListener(_onEvent);
  }

  Future<void> _onEvent(String event, Map<Object?, dynamic>? data) async {
    switch (event) {
      case "playNext":
        await playNextHandler();
      case "playPrev":
        await playPrevHandler();
      case "setLoop":
        await setLoopHandler(data!["loop"]);
      case "advance":
        eventStream.add(AudioPlayerEvent.advance);
      case "state":
        eventStream.add(switch (data!["state"] as String) {
          "playing" => AudioPlayerEvent.playing,
          "paused" => AudioPlayerEvent.paused,
          "loading" => AudioPlayerEvent.loading,
          _ => AudioPlayerEvent.stopped,
        });
      case "playerCreated":
        if (_initTime != null &&
            DateTime.now().difference(_initTime!) >
                const Duration(seconds: 1)) {
          // the native player was recreated
          await restartPlayback?.call();
        }
    }
  }

  Future<void> _onWorkaroundsChanged() async {
    await _methodChannel.invokeMethod("configure", {
      "treatStopAsPause": _settings.workarounds.stopIsPause,
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
    await super.configureServerURL(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
      updateCurrentMediaItem: updateCurrentMediaItem,
    );
    await _methodChannel.invokeMethod("configure", {
      "supportsTimeOffset": supportsTimeOffset,
      "supportsTimeOffsetMs": supportsTimeOffsetMs,
      "treatStopAsPause": _settings.workarounds.stopIsPause,
    });
  }

  @override
  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    super.setCurrent(current, next: next, pos: pos);
    await _methodChannel.invokeMethod("setCurrent", {
      "current": await _songToMap(current),
      if (pos > Duration.zero) "pos": pos.inMilliseconds,
      if (next != null) "next": await _songToMap(next),
    });
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);
    await _methodChannel.invokeMethod("setNext", {
      if (next != null) "next": await _songToMap(next),
    });
  }

  @override
  Future<void> pause() async {
    await _methodChannel.invokeMethod("pause");
  }

  @override
  Future<void> play() async {
    await _methodChannel.invokeMethod("play");
  }

  @override
  Future<void> seek(Duration position) async {
    await _methodChannel.invokeMethod("seek", {"pos": position.inMilliseconds});
    positionDiscontinuity.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _methodChannel.invokeMethod("setVolume", {"volume": volume});
  }

  @override
  Future<void> stop() async {
    await _methodChannel.invokeMethod("stop");
  }

  @override
  Future<void> dispose() async {
    _settings.workarounds.removeListener(_onWorkaroundsChanged);
    _methodChannel.removeEventListener(_onEvent);
    await _methodChannel.invokeMethod("dispose");
    await super.dispose();
  }

  Future<Map<String, dynamic>?> _songToMap(Song? s) async {
    if (s == null) return null;
    final coverKey = CoverRepository.getKey(s.coverId, 512);
    final coverFile = await _coverRepo.getFileFromCache(coverKey);
    if (coverFile == null) {
      _coverRepo
          .getSingleFile(coverKey)
          .then(
            (file) async {
              final bytes = await file.readAsBytes();
              _methodChannel.invokeMethod("updateCover", {
                "songId": s.id,
                "coverBytes": bytes,
              });
            },
            onError: (err) {
              // ignore
            },
          );
    }
    return AndroidMediaItem(
      id: s.id,
      browsable: false,
      playable: true,
      title: s.title,
      album: s.album?.name,
      artist: s.displayArtist,
      discNumber: s.discNr,
      durationMs: s.duration?.inMilliseconds,
      genre: s.genres.firstOrNull,
      trackNumber: s.trackNr,
      releaseYear: s.releaseDate?.year,
      releaseMonth: s.releaseDate?.month,
      releaseDay: s.releaseDate?.day,
      artworkData: await coverFile?.file.readAsBytes(),
      // time offset is handled in android
      uri: constructStreamUri(s).toString(),
    ).toMsgData();
  }
}
