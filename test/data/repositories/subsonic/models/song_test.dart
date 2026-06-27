import 'dart:convert';

import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Song roundTrip(Song song) =>
      Song.fromJson(jsonDecode(jsonEncode(song.toJson())));

  test('round-trips a fully populated song', () {
    final song = Song(
      id: 'song-1',
      coverId: 'cover-1',
      title: 'Title',
      displayArtist: 'Artist A & Artist B',
      artists: [
        (id: 'a1', name: 'Artist A'),
        (id: 'a2', name: 'Artist B'),
      ],
      album: (id: 'alb-1', name: 'Album'),
      genres: ['Rock', 'Pop'],
      duration: const Duration(minutes: 3, seconds: 30),
      bpm: 120,
      trackNr: 4,
      discNr: 1,
      trackGain: -6.5,
      albumGain: -7.0,
      fallbackGain: -8.0,
      originalDate: Date(year: 1999, month: 5, day: 1),
      releaseDate: Date(year: 2000),
      contentType: 'audio/flac',
      sampleRate: 44100,
      bitDepth: 16,
      bitRate: 1411,
    );

    final restored = roundTrip(song);

    expect(restored.id, 'song-1');
    expect(restored.coverId, 'cover-1');
    expect(restored.title, 'Title');
    expect(restored.displayArtist, 'Artist A & Artist B');
    expect(restored.artists.toList(), [
      (id: 'a1', name: 'Artist A'),
      (id: 'a2', name: 'Artist B'),
    ]);
    expect(restored.album, (id: 'alb-1', name: 'Album'));
    expect(restored.genres.toList(), ['Rock', 'Pop']);
    expect(restored.duration, const Duration(minutes: 3, seconds: 30));
    expect(restored.bpm, 120);
    expect(restored.trackNr, 4);
    expect(restored.discNr, 1);
    expect(restored.trackGain, -6.5);
    expect(restored.albumGain, -7.0);
    expect(restored.fallbackGain, -8.0);
    expect(restored.originalDate, Date(year: 1999, month: 5, day: 1));
    expect(restored.releaseDate, Date(year: 2000));
    expect(restored.contentType, 'audio/flac');
    expect(restored.sampleRate, 44100);
    expect(restored.bitDepth, 16);
    expect(restored.bitRate, 1411);
  });

  test('round-trips a song with all optional fields absent', () {
    final song = Song(
      id: 'song-2',
      coverId: '',
      title: 'Minimal',
      displayArtist: 'Unknown',
      artists: const [],
      album: null,
      genres: const [],
      duration: null,
      bpm: null,
      trackNr: null,
      discNr: null,
      trackGain: null,
      albumGain: null,
      fallbackGain: null,
      originalDate: null,
      releaseDate: null,
      contentType: null,
      sampleRate: null,
      bitDepth: null,
      bitRate: null,
    );

    final restored = roundTrip(song);

    expect(restored.id, 'song-2');
    expect(restored.title, 'Minimal');
    expect(restored.artists.toList(), isEmpty);
    expect(restored.album, isNull);
    expect(restored.genres.toList(), isEmpty);
    expect(restored.duration, isNull);
    expect(restored.bpm, isNull);
    expect(restored.originalDate, isNull);
    expect(restored.releaseDate, isNull);
    expect(restored.contentType, isNull);
  });
}