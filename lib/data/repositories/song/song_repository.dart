/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/repositories/subsonic/models/helpers.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/database/converters/artist_ref_list_converter.dart';
import 'package:crossonic/data/services/database/converters/date_converter.dart'
    as dbdate;
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:drift/drift.dart';

class SongRepository {
  final Database _db;
  final FavoritesRepository _favorites;

  SongRepository({required Database db, required FavoritesRepository favorites})
    : _db = db,
      _favorites = favorites;

  Song songFromDBModel(SongTableData model) {
    return Song(
      id: model.id,
      coverId: model.coverId,
      title: model.title,
      displayArtist: model.displayArtist,
      artists: model.artists.map((a) => (id: a.id, name: a.name)),
      album: model.albumId != null
          ? (id: model.albumId!, name: model.albumName!)
          : null,
      genres: model.genres,
      duration: model.durationMs != null
          ? Duration(milliseconds: model.durationMs!)
          : null,
      bpm: model.bpm,
      trackNr: model.trackNr,
      discNr: model.discNr,
      trackGain: model.trackGain,
      albumGain: model.albumGain,
      fallbackGain: model.fallbackGain,
      originalDate: model.originalDate != null
          ? Date(
              year: model.originalDate!.year,
              month: model.originalDate!.month,
              day: model.originalDate!.day,
            )
          : null,
      releaseDate: model.releaseDate != null
          ? Date(
              year: model.releaseDate!.year,
              month: model.releaseDate!.month,
              day: model.releaseDate!.day,
            )
          : null,
    );
  }

  Future<Song> songFromChildModel(ChildModel child) async {
    final song = _songFromChildModel(child);
    await _storeSongsInDB([song]);
    _updateSongFavorites([child]);
    return song;
  }

  Future<Iterable<Song>> songsFromChildModels(
    Iterable<ChildModel> children,
  ) async {
    if (children.isEmpty) return [];

    final songs = children.map((c) => _songFromChildModel(c));
    await _storeSongsInDB(songs);
    _updateSongFavorites(children);
    return songs;
  }

  void _updateSongFavorites(Iterable<ChildModel>? songs) {
    _favorites.updateAll(
      (songs ?? []).map(
        (c) => (type: FavoriteType.song, id: c.id, starred: c.starred),
      ),
    );
  }

  Future<void> _storeSongsInDB(Iterable<Song> songs) async {
    await _db.managers.songTable.bulkCreate(
      (o) => songs.map(
        (s) => o(
          id: s.id,
          title: s.title,
          coverId: s.coverId,
          displayArtist: s.displayArtist,
          albumName: Value(s.album?.name),
          albumId: Value(s.album?.id),
          updated: DateTime.now(),
          durationMs: Value(s.duration?.inMilliseconds),
          artists: Value(
            s.artists.map((a) => ArtistRef(id: a.id, name: a.name)).toList(),
          ),
          genres: Value(s.genres.toList()),
          bpm: Value(s.bpm),
          trackNr: Value(s.trackNr),
          discNr: Value(s.discNr),
          trackGain: Value(s.trackGain),
          albumGain: Value(s.albumGain),
          fallbackGain: Value(s.fallbackGain),
          originalDate: Value(
            s.originalDate != null
                ? dbdate.Date(
                    year: s.originalDate!.year,
                    month: s.originalDate!.month,
                    day: s.originalDate!.day,
                  )
                : null,
          ),
          releaseDate: Value(
            s.releaseDate != null
                ? dbdate.Date(
                    year: s.releaseDate!.year,
                    month: s.releaseDate!.month,
                    day: s.releaseDate!.day,
                  )
                : null,
          ),
        ),
      ),
      onConflict: DoUpdate.withExcluded(
        (old, excluded) => SongTableCompanion.custom(
          title: excluded.title,
          releaseDate: excluded.releaseDate,
          originalDate: excluded.originalDate,
          fallbackGain: excluded.fallbackGain,
          albumGain: excluded.albumGain,
          trackGain: excluded.trackGain,
          discNr: excluded.discNr,
          trackNr: excluded.trackNr,
          bpm: excluded.bpm,
          genres: excluded.genres,
          artists: excluded.artists,
          displayArtist: excluded.displayArtist,
          coverId: excluded.coverId,
          durationMs: excluded.durationMs,
          albumId: excluded.albumId,
          albumName: excluded.albumName,
          updated: excluded.updated,
        ),
      ),
    );
  }

  Song _songFromChildModel(ChildModel child) {
    Date? originalDate;
    if (child.originalReleaseDate != null &&
        child.originalReleaseDate!.year != null) {
      originalDate = Date.fromItemDateModel(child.originalReleaseDate!);
    } else if (child.year != null) {
      originalDate = Date(year: child.year!, month: null, day: null);
    }

    Date? releaseDate;
    if (child.releaseDate != null && child.releaseDate!.year != null) {
      releaseDate = Date.fromItemDateModel(child.releaseDate!);
    } else if (child.year != null) {
      releaseDate = Date(year: child.year!, month: null, day: null);
    }

    if (releaseDate != null) {
      if (originalDate != null) {
        if (originalDate > releaseDate) {
          releaseDate = originalDate;
        }
      } else {
        originalDate = releaseDate;
      }
    }

    return Song(
      id: child.id,
      coverId: child.coverArt ?? child.id,
      title: child.title,
      displayArtist:
          emptyToNull(child.displayArtist) ??
          child.artists?.map((a) => a.name).join(", ") ??
          child.artist ??
          child.displayAlbumArtist ??
          child.albumArtists?.map((a) => a.name).join(", ") ??
          "Unknown artist",
      artists:
          child.artists ??
          child.albumArtists ??
          (emptyToNull(child.artistId) != null &&
                  emptyToNull(child.artist) != null
              ? [(id: child.artistId!, name: child.artist!)]
              : null) ??
          [],
      album:
          emptyToNull(child.albumId) != null && emptyToNull(child.album) != null
          ? (id: child.albumId!, name: child.album!)
          : null,
      genres: child.genres != null
          ? child.genres!.map((g) => g.name)
          : (child.genre != null && child.genre!.isNotEmpty
                ? [child.genre!]
                : []),
      duration: child.duration != null
          ? Duration(seconds: child.duration!)
          : null,
      releaseDate: releaseDate,
      originalDate: originalDate,
      bpm: child.bpm,
      trackNr: child.track,
      discNr: child.discNumber,
      trackGain: child.replayGain?.trackGain,
      albumGain: child.replayGain?.albumGain,
      fallbackGain: child.replayGain?.fallbackGain,
    );
  }
}
