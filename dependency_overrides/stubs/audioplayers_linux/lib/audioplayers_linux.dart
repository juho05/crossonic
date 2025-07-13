import 'dart:typed_data';

import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart';

class AudioplayersPluginLinux extends AudioplayersPlatformInterface {
  static void registerWith() {
    AudioplayersPlatformInterface.instance = AudioplayersPluginLinux();
  }

  @override
  Future<void> create(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> emitError(String playerId, String code, String message) {
    throw UnimplementedError();
  }

  @override
  Future<void> emitLog(String playerId, String message) {
    throw UnimplementedError();
  }

  @override
  Future<int?> getCurrentPosition(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<int?> getDuration(String playerId) {
    throw UnimplementedError();
  }

  @override
  Stream<AudioEvent> getEventStream(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> pause(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> release(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> resume(String playerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> seek(String playerId, Duration position) {
    throw UnimplementedError();
  }

  @override
  Future<void> setAudioContext(String playerId, AudioContext audioContext) {
    throw UnimplementedError();
  }

  @override
  Future<void> setBalance(String playerId, double balance) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPlaybackRate(String playerId, double playbackRate) {
    throw UnimplementedError();
  }

  @override
  Future<void> setPlayerMode(String playerId, PlayerMode playerMode) {
    throw UnimplementedError();
  }

  @override
  Future<void> setReleaseMode(String playerId, ReleaseMode releaseMode) {
    throw UnimplementedError();
  }

  @override
  Future<void> setSourceBytes(String playerId, Uint8List bytes,
      {String? mimeType}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setSourceUrl(String playerId, String url,
      {bool? isLocal, String? mimeType}) {
    throw UnimplementedError();
  }

  @override
  Future<void> setVolume(String playerId, double volume) {
    throw UnimplementedError();
  }

  @override
  Future<void> stop(String playerId) {
    throw UnimplementedError();
  }
}
