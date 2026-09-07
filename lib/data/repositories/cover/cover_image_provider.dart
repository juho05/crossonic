/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';
import 'dart:ui' as ui;

import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class CoverImageProvider extends ImageProvider<CoverImageProvider> {
  final CoverRepository _repository;
  final String coverId;

  // side length of the cover file requested from the server
  final int resolution;

  // side length in pixels the shorter image edge is decoded to, null keeps
  // the file resolution
  final int? targetSize;

  const CoverImageProvider(
    this._repository, {
    required this.coverId,
    required this.resolution,
    this.targetSize,
  });

  // image cache keys that have been loaded per cover id, so all cached
  // variants of a cover can be evicted when the cover changes
  static final Map<String, Set<CoverImageProvider>> _loadedKeys = {};

  static void evictCover(String coverId) {
    final keys = _loadedKeys.remove(coverId);
    if (keys == null) return;
    for (final key in keys) {
      PaintingBinding.instance.imageCache.evict(key);
    }
  }

  @override
  Future<CoverImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CoverImageProvider key,
    ImageDecoderCallback decode,
  ) {
    (_loadedKeys[coverId] ??= {}).add(key);
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1.0,
      debugLabel: "cover $coverId@$resolution",
      informationCollector: () => [
        DiagnosticsProperty<ImageProvider>("Image provider", this),
      ],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final file = await _repository.loadCoverFile(coverId, resolution);
    final buffer = await ui.ImmutableBuffer.fromFilePath(file.path);
    return decode(
      buffer,
      getTargetSize: targetSize != null ? _decodeSize : null,
    );
  }

  ui.TargetImageSize _decodeSize(int intrinsicWidth, int intrinsicHeight) {
    final shorterSide = min(intrinsicWidth, intrinsicHeight);
    if (shorterSide <= targetSize!) {
      return ui.TargetImageSize(width: intrinsicWidth, height: intrinsicHeight);
    }
    final scale = targetSize! / shorterSide;
    return ui.TargetImageSize(
      width: (intrinsicWidth * scale).round(),
      height: (intrinsicHeight * scale).round(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CoverImageProvider &&
        other.coverId == coverId &&
        other.resolution == resolution &&
        other.targetSize == targetSize;
  }

  @override
  int get hashCode => Object.hash(coverId, resolution, targetSize);

  @override
  String toString() =>
      "CoverImageProvider($coverId, resolution: $resolution, targetSize: $targetSize)";
}
