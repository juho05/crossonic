/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class Song {
  final String id;
  final String coverId;
  final String title;
  final String displayArtist;
  final Iterable<({String id, String name})> artists;
  final ({String id, String name})? album;
  final Iterable<String> genres;
  final Duration? duration;
  final int? bpm;
  final int? trackNr;
  final int? discNr;
  final double? trackGain;
  final double? albumGain;
  final double? fallbackGain;
  final Date? originalDate;
  final Date? releaseDate;
  final String? contentType;
  final int? sampleRate;
  final int? bitDepth;
  final int? bitRate;

  Song({
    required this.id,
    required this.coverId,
    required this.title,
    required this.displayArtist,
    required this.artists,
    required this.album,
    required this.genres,
    required this.duration,
    required this.bpm,
    required this.trackNr,
    required this.discNr,
    required this.trackGain,
    required this.albumGain,
    required this.fallbackGain,
    required this.originalDate,
    required this.releaseDate,
    required this.contentType,
    required this.sampleRate,
    required this.bitDepth,
    required this.bitRate,
  });

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);

  Map<String, dynamic> toJson() => _$SongToJson(this);
}
