import 'dart:async';

import 'package:crossonic/data/repositories/audio/players/player.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter/services.dart';

class AudioPlayerAndroid extends AudioPlayer {
  static const _methodChannel = MethodChannel(
    "org.crossonic.app.player.methods",
  );
  static const _eventChannel = EventChannel("org.crossonic.app.player.events");

  AudioPlayerAndroid({
    required super.downloader,
    required super.setVolumeHandler,
    required super.setQueueHandler,
    required super.setLoopHandler,
    required super.playNextHandler,
    required super.playPrevHandler,
    required super.restartPlayback,
  });

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

  StreamSubscription? _eventStreamSub;
  @override
  Future<void> init({
    required Uri streamUri,
    required Uri coverUri,
    required bool supportsTimeOffset,
    required bool supportsTimeOffsetMs,
    int? maxBitRate,
    String? format,
  }) async {
    DateTime initTime = DateTime.now();
    await super.init(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
    );
    _eventStreamSub = _eventChannel.receiveBroadcastStream().listen((
      event,
    ) async {
      final eventObj = event as Map<Object?, dynamic>;
      final data = eventObj["data"] as Map<Object?, dynamic>?;
      switch (eventObj["event"]) {
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
          if (DateTime.now().difference(initTime) >
              const Duration(seconds: 1)) {
            // the native player was recreated
            await restartPlayback?.call();
          }
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
    await super.configureServerURL(
      streamUri: streamUri,
      coverUri: coverUri,
      supportsTimeOffset: supportsTimeOffset,
      supportsTimeOffsetMs: supportsTimeOffsetMs,
      maxBitRate: maxBitRate,
      format: format,
      updateCurrentMediaItem: updateCurrentMediaItem,
    );
    await _methodChannel.invokeMethod("setSupportedFeatures", {
      "timeOffset": supportsTimeOffset,
      "timeOffsetMs": supportsTimeOffsetMs,
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
      "current": _songToMap(current),
      if (pos > Duration.zero) "pos": pos.inMilliseconds,
      if (next != null) "next": _songToMap(next),
    });
  }

  @override
  Future<void> setNext(Song? next) async {
    super.setNext(next);
    await _methodChannel.invokeMethod("setNext", {
      if (next != null) "next": _songToMap(next),
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
    await _methodChannel.invokeMethod("dispose");
    await _eventStreamSub?.cancel();
    await super.dispose();
  }

  Map<String, dynamic>? _songToMap(Song? s) {
    if (s == null) return null;
    return {
      "id": s.id,
      "title": s.title,
      if (s.album != null) "album": s.album!.name,
      "artist": s.displayArtist,
      if (s.discNr != null) "discNumber": s.discNr,
      if (s.duration != null) "duration": s.duration!.inMilliseconds,
      if (s.genres.isNotEmpty) "genre": s.genres.first,
      if (s.trackNr != null) "trackNumber": s.trackNr,
      if (s.releaseDate?.year != null) "releaseYear": s.releaseDate!.year,
      if (s.releaseDate?.month != null) "releaseMonth": s.releaseDate!.month,
      if (s.releaseDate?.day != null) "releaseDay": s.releaseDate!.day,
      "coverUri": constructCoverUri(s).toString(),
      // time offset is handled in android
      "uri": constructStreamUri(s).toString(),
    };
  }
}
