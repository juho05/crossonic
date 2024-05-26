import 'dart:async';

import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/services/audio_handler/players/player.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

class AudioPlayerGstreamer implements CrossonicAudioPlayer {
  static const _methodChan =
      MethodChannel("crossonic.julianh.de/gstreamer/method");
  static const _eventChan =
      EventChannel("crossonic.julianh.de/gstreamer/event");

  AudioPlayerGstreamer() {
    _eventChan.receiveBroadcastStream().listen((event) {
      final statusStr = event as String;
      final status = AudioPlayerEvent.values.byName(statusStr);
      if (status != eventStream.value) {
        eventStream.add(status);
      }
    });
  }

  @override
  Future<void> dispose() async {
    await stop();
  }

  @override
  Future<void> pause() async {
    await _methodChan.invokeMethod("pause");
  }

  @override
  Future<void> play() async {
    await _methodChan.invokeMethod("play");
  }

  @override
  Future<void> seek(Duration position) async {
    await _methodChan
        .invokeListMethod("seek", {"position": position.inMilliseconds});
  }

  @override
  Future<void> stop() async {
    // TODO properly stop
    _eventStream.add(AudioPlayerEvent.stopped);
    await pause();
  }

  @override
  Future<Duration> get position async => Duration(
      milliseconds: await _methodChan.invokeMethod<int>("getPosition") ?? 0);

  @override
  Future<Duration> get bufferedPosition async => Duration.zero;

  final BehaviorSubject<AudioPlayerEvent> _eventStream =
      BehaviorSubject.seeded(AudioPlayerEvent.stopped);
  @override
  BehaviorSubject<AudioPlayerEvent> get eventStream => _eventStream;

  @override
  Future<void> setCurrent(Media media, Uri url) async {
    _methodChan.invokeMethod("setCurrent", {"url": url.toString()});
  }

  @override
  Future<void> setNext(Media? media, Uri? url) async {
    _methodChan.invokeMethod("setNext", {"url": url?.toString()});
  }
}
