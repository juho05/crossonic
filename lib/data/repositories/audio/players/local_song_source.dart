/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

abstract interface class LocalSongSource {
  bool isDownloaded(String id);

  String? getPath(String id);
}

class CompositeLocalSource implements LocalSongSource {
  final List<LocalSongSource> _sources;

  CompositeLocalSource(this._sources);

  @override
  bool isDownloaded(String id) => _sources.any((s) => s.isDownloaded(id));

  @override
  String? getPath(String id) {
    for (final source in _sources) {
      final path = source.getPath(id);
      if (path != null) return path;
    }
    return null;
  }
}
