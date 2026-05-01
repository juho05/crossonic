/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/casting/local_device.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum AudioPlayerEvent { advance, stopped, loading, playing, paused }

abstract class AudioPlayer {
  final SongDownloader _downloader;

  Device get device => const LocalDevice();

  @protected
  final StreamController<void> restartPlaybackStream =
      StreamController.broadcast();

  Stream<void> get restartPlayback => restartPlaybackStream.stream;

  StreamSubscription? _eventStreamSub;

  AudioPlayer({required SongDownloader downloader}) : _downloader = downloader {
    _eventStreamSub = eventStream.listen((event) {
      if (event == AudioPlayerEvent.stopped) {
        currentSong.value = null;
        nextSong.value = null;
        return;
      }
      if (event == AudioPlayerEvent.advance) {
        currentSong.value = nextSong.value;
        _canSeek = _nextCanSeek;
      }
    });
  }

  late Uri _streamUri;
  late Uri _coverUri;

  late bool _supportsTimeOffset;

  @protected
  bool get supportsTimeOffset => _supportsTimeOffset;

  late bool _supportsTimeOffsetMs;

  @protected
  bool get supportsTimeOffsetMs => _supportsTimeOffsetMs;

  int? _maxBitRate;

  @protected
  int? get maxBitRate => _maxBitRate;

  String? _format;

  @protected
  String? get format => _format;

  bool get supportsFilePlayback => false;

  ValueNotifier<Song?> currentSong = ValueNotifier(null);
  ValueNotifier<Song?> nextSong = ValueNotifier(null);

  Future<void> configureServerURL({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
    bool updateCurrentMediaItem = false,
  }) async {
    _streamUri = streamUri;
    _coverUri = coverUri;
    _supportsTimeOffset = supportsTimeOffset;
    _supportsTimeOffsetMs = supportsTimeOffsetMs;
    _maxBitRate = _maxBitRate;
    _format = format;
    if (updateCurrentMediaItem && currentSong.value != null) {
      await setCurrent(
        currentSong.value!,
        next: nextSong.value,
        pos: await position,
      );
    } else if (nextSong.value != null) {
      await setNext(nextSong.value);
    }
  }

  final BehaviorSubject<AudioPlayerEvent> eventStream = BehaviorSubject.seeded(
    AudioPlayerEvent.stopped,
  );

  final BehaviorSubject<Duration> positionDiscontinuity =
      BehaviorSubject.seeded(Duration.zero);

  Future<Duration> get position;

  Future<Duration> get bufferedPosition;

  Future<double> get volume;

  Future<void> setVolume(double volume);

  Future<void> setCurrent(
    Song current, {
    required Song? next,
    Duration pos = Duration.zero,
  }) async {
    currentSong.value = current;
    nextSong.value = next;
    _canSeek =
        _format == "raw" ||
        (currentSong.value != null &&
            supportsFilePlayback &&
            _downloader.isDownloaded(currentSong.value!.id));
  }

  Future<void> setNext(Song? next) async {
    nextSong.value = next;
    _nextCanSeek =
        _format == "raw" ||
        (nextSong.value != null &&
            supportsFilePlayback &&
            _downloader.isDownloaded(nextSong.value!.id));
  }

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Future<void> seek(Duration pos);

  bool _canSeek = true;
  bool _nextCanSeek = true;

  @protected
  bool get canSeek => !supportsTimeOffset || _canSeek;

  @protected
  Uri? constructStreamUri(Song? s, {Duration? pos}) {
    if (s == null) return null;

    if ((pos == null || pos == Duration.zero) && supportsFilePlayback) {
      final path = _downloader.getPath(s.id);
      if (path != null) return path.toFileUri();
    }

    final queryParams = {
      "id": [s.id],
      if (_format != null) "format": [_format],
      if (_maxBitRate != null) "maxBitRate": [_maxBitRate.toString()],
      if (pos != null && supportsTimeOffsetMs)
        "timeOffsetMs": [pos.inMilliseconds.toString()],
      if (pos != null && !supportsTimeOffsetMs && supportsTimeOffset)
        "timeOffset": [(pos.inMilliseconds / 1000).round().toString()],
      ..._streamUri.queryParametersAll,
    };
    return Uri(
      host: _streamUri.host,
      path: _streamUri.path,
      scheme: _streamUri.scheme,
      port: _streamUri.port,
      userInfo: _streamUri.userInfo,
      fragment: _streamUri.fragment.isNotEmpty ? _streamUri.fragment : null,
      queryParameters: queryParams,
    );
  }

  @protected
  Uri? constructCoverUri(Song? s) {
    if (s == null) return null;
    final queryParams = {
      "id": [s.coverId],
      "size": ["512"],
      ..._coverUri.queryParametersAll,
    };
    return Uri(
      host: _coverUri.host,
      path: _coverUri.path,
      scheme: _coverUri.scheme,
      port: _coverUri.port,
      userInfo: _coverUri.userInfo,
      fragment: _streamUri.fragment.isNotEmpty ? _streamUri.fragment : null,
      queryParameters: queryParams,
    );
  }

  Future<void> dispose() async {
    _eventStreamSub?.cancel();
  }
}
