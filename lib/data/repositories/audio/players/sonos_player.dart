/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/audio/casting/device.dart';
import 'package:crossonic/data/repositories/audio/players/player.dart';

class SonosPlayer extends AudioPlayer {
  final Device _device;

  @override
  Device get device => _device;

  SonosPlayer({required super.downloader, required Device device})
    : _device = device;

  @override
  // TODO: implement position
  Future<Duration> get position => throw UnimplementedError();

  @override
  // TODO: implement bufferedPosition
  Future<Duration> get bufferedPosition => throw UnimplementedError();

  @override
  // TODO: implement volume
  Future<double> get volume => throw UnimplementedError();

  @override
  Future<void> play() {
    // TODO: implement play
    throw UnimplementedError();
  }

  @override
  Future<void> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  Future<void> seek(Duration position) {
    // TODO: implement seek
    throw UnimplementedError();
  }

  @override
  Future<void> setVolume(double volume) {
    // TODO: implement setVolume
    throw UnimplementedError();
  }
}
