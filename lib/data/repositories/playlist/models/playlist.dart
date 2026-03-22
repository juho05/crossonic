/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

class Playlist {
  final String id;
  final String name;
  final String? comment;
  final int songCount;
  final Duration duration;
  final DateTime created;
  final DateTime changed;
  final String? coverId;
  final bool download;

  Playlist({
    required this.id,
    required this.name,
    required this.comment,
    required this.songCount,
    required this.duration,
    required this.created,
    required this.changed,
    required this.coverId,
    required this.download,
  });

  @override
  bool operator ==(Object other) {
    if (other is! Playlist) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
