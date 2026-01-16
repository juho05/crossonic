import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum AudioPlayerEvent { advance, stopped, loading, playing, paused }

abstract class AudioPlayer {
  final SongDownloader _downloader;

  @protected
  final Future<void> Function(double volume) setVolumeHandler;
  @protected
  final Future<void> Function(Iterable<Song> songs) setQueueHandler;
  @protected
  final Future<void> Function(bool loop) setLoopHandler;
  @protected
  final Future<void> Function() playNextHandler;
  @protected
  final Future<void> Function() playPrevHandler;

  AudioPlayer({
    required SongDownloader downloader,
    required this.setVolumeHandler,
    required this.setQueueHandler,
    required this.setLoopHandler,
    required this.playNextHandler,
    required this.playPrevHandler,
  }) : _downloader = downloader;

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

  @protected
  ValueNotifier<Song?> currentSong = ValueNotifier(null);
  @protected
  ValueNotifier<Song?> nextSong = ValueNotifier(null);

  StreamSubscription? _eventStreamSub;
  Future<void> init({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
  }) async {
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

    await configureServerURL(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
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
            _downloader.isDownloaded(currentSong.value!.id));
  }

  Future<void> setNext(Song? next) async {
    nextSong.value = next;
    _nextCanSeek =
        _format == "raw" ||
        (nextSong.value != null &&
            _downloader.isDownloaded(nextSong.value!.id));
  }

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  Future<void> seek(Duration position);

  bool _canSeek = true;
  bool _nextCanSeek = true;
  @protected
  bool get canSeek => !supportsTimeOffset || _canSeek;

  @protected
  Uri? constructStreamUri(Song? s, {Duration? pos}) {
    if (s == null) return null;

    if (pos == null || pos == Duration.zero) {
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
      fragment: _streamUri.fragment,
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
      fragment: _coverUri.fragment,
      queryParameters: queryParams,
    );
  }

  Future<void> dispose() async {
    _eventStreamSub?.cancel();
  }
}
