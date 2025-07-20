import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

import 'exoplayer_platform_interface.dart';

/// An implementation of [ExoPlayerPlatform] that uses method channels.
class MethodChannelExoPlayer extends ExoPlayerPlatform {
  final methodChannel = const MethodChannel('org.crossonic.exoplayer.method');

  final eventChannel = const EventChannel('org.crossonic.exoplayer.event');

  final BehaviorSubject<void> _advanceStream = BehaviorSubject();

  @override
  Stream<void> get advanceStream => _advanceStream.stream;

  final BehaviorSubject<String> _stateStream = BehaviorSubject<String>();
  @override
  Stream<String> get stateStream => _stateStream;

  final BehaviorSubject<Duration> _restartStream = BehaviorSubject<Duration>();
  @override
  Stream<Duration> get restartStream => _restartStream;

  final BehaviorSubject<(Object, StackTrace)> _errorStream =
      BehaviorSubject<(Object, StackTrace)>();
  @override
  Stream<(Object, StackTrace)> get errorStream => _errorStream.stream;

  bool _initialized = false;

  @override
  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    eventChannel
        .receiveBroadcastStream()
        .doOnError((error, stackTrace) => _errorStream.add((error, stackTrace)))
        .listen((event) {
          final eventObj = event as Map<Object?, dynamic>;
          final data = eventObj["data"] as Map<Object?, dynamic>?;
          switch (eventObj["name"]) {
            case "advance":
              _advanceStream.add(null);
            case "state":
              _stateStream.add(data!["state"] as String);
            case "restart":
              _restartStream.add(Duration(milliseconds: data!["pos"] as int));
          }
        });
  }

  @override
  Future<Duration> get position async => Duration(
    milliseconds: await methodChannel.invokeMethod<int>("getPosition") ?? 0,
  );

  @override
  Future<Duration> get bufferedPosition async => Duration(
    milliseconds:
        await methodChannel.invokeMethod<int>("getBufferedPosition") ?? 0,
  );

  @override
  Future<void> dispose() => methodChannel.invokeMethod("dispose");

  @override
  Future<void> init() => methodChannel.invokeMethod("init");

  @override
  Future<void> pause() => methodChannel.invokeMethod("pause");

  @override
  Future<void> play() => methodChannel.invokeMethod("play");

  @override
  Future<void> seek(Duration position) =>
      methodChannel.invokeMethod("seek", {"pos": position.inMilliseconds});

  @override
  Future<void> setCurrent(Uri url, [Duration? pos]) =>
      methodChannel.invokeMethod("setCurrent", {
        "uri": url.toString(),
        "pos": pos?.inMilliseconds ?? 0,
      });

  @override
  Future<void> setNext(Uri? url) =>
      methodChannel.invokeMethod("setNext", {"uri": url.toString()});

  @override
  Future<void> setVolume(double volume) =>
      methodChannel.invokeMethod("setVolume", {"volume": volume});
  @override
  Future<void> stop() => methodChannel.invokeMethod("stop");
}
