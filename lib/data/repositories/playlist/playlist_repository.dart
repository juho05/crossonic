import 'dart:convert';

import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/playlist_model.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

class PlaylistRepository extends ChangeNotifier {
  final SubsonicService _subsonic;
  final FavoritesRepository _favorites;
  final AuthRepository _auth;
  final Database _db;

  PlaylistRepository({
    required SubsonicService subsonic,
    required FavoritesRepository favorites,
    required AuthRepository auth,
    required Database db,
  })  : _subsonic = subsonic,
        _favorites = favorites,
        _auth = auth,
        _db = db {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  Future<Result<void>> reorder(String id, int oldIndex, int newIndex) async {
    try {
      await _db.transaction(() async {
        final song = await _db.managers.playlistSongTable
            .filter((f) => f.playlistId.id.equals(id) & f.index(oldIndex))
            .getSingle();
        if (newIndex > oldIndex) {
          newIndex--;
          await _db.customUpdate(
            "UPDATE playlist_song SET index = index - 1 WHERE playlist_id = ? AND index > ? AND index <= ?",
            variables: [
              Variable.withString(id),
              Variable.withInt(oldIndex),
              Variable.withInt(newIndex)
            ],
            updates: {_db.playlistSongTable},
          );
        } else {
          await _db.customUpdate(
            "UPDATE playlist_song SET index = index + 1 WHERE playlist_id = ? AND index < ? AND index >= ?",
            variables: [
              Variable.withString(id),
              Variable.withInt(oldIndex),
              Variable.withInt(newIndex)
            ],
            updates: {_db.playlistSongTable},
          );
        }
        await _db.managers.playlistSongTable.create((o) => o(
              playlistId: id,
              songId: song.songId,
              index: newIndex,
              childModelJson: song.childModelJson,
            ));
      });
      notifyListeners();
    } on Exception catch (e) {
      return Result.error(e);
    }

    try {
      final dbSongs = await _db.managers.playlistSongTable
          .filter((f) => f.playlistId.id.equals(id))
          .orderBy((o) => o.index.asc())
          .get();

      final result = await _subsonic.createPlaylist(_auth.con,
          playlistId: id, songIds: dbSongs.map((s) => s.songId));
      switch (result) {
        case Err():
          return Result.error(result.error);
        case Ok():
      }
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      refresh(forceRefresh: true, refreshIds: {id});
    }

    return Result.ok(null);
  }

  Future<Result<void>> addTracks(String id, Iterable<Song> songs) async {
    final result = await _subsonic.updatePlaylist(_auth.con, id,
        songIdToAdd: songs.map((s) => s.id));
    if (result is Ok) {
      await refresh(refreshIds: {id});
    } else {
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> removeTrack(String id, int index) async {
    final result = await _subsonic
        .updatePlaylist(_auth.con, id, songIndexToRemove: [index]);
    if (result is Ok) {
      await refresh(refreshIds: {id});
    } else {
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> updatePlaylistMetadata(
    String id, {
    String? name,
    String? comment,
  }) async {
    if (name == null && comment == null) return Result.ok(null);
    final result = await _subsonic.updatePlaylist(
      _auth.con,
      id,
      name: name,
      comment: comment,
    );
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    try {
      await _db.managers.playlistTable.filter((f) => f.id(id)).update(
            (o) => o(
              name: Value.absentIfNull(name),
              comment: Value.absentIfNull(comment),
              changed: Value(DateTime.now()),
            ),
          );
      notifyListeners();
    } on Exception catch (e) {
      return Result.error(e);
    }
    return Result.ok(null);
  }

  Future<Result<List<Playlist>>> getPlaylists() async {
    try {
      final playlists = await _db.managers.playlistTable.get();
      return Result.ok(playlists
          .map((p) => Playlist(
                id: p.id,
                name: p.name,
                comment: p.comment,
                created: p.created,
                changed: p.changed,
                duration: Duration(milliseconds: p.durationMs),
                songCount: p.songCount,
                coverId: p.coverArt,
              ))
          .toList());
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<({Playlist playlist, List<Song> tracks})?>> getPlaylist(
      String id) async {
    try {
      final playlist = await _db.managers.playlistTable
          .filter((f) => f.id(id))
          .withReferences()
          .getSingleOrNull();
      if (playlist == null) return Result.ok(null);
      final dbSongs = await playlist.$2.playlistSongTableRefs
          .orderBy((o) => o.index.asc())
          .get();
      final p = playlist.$1;

      final songs = dbSongs
          .map((s) => Song.fromChildModel(
              ChildModel.fromJson(jsonDecode(s.childModelJson))))
          .toList();

      Duration duration = Duration.zero;
      for (final s in songs) {
        duration += s.duration ?? Duration.zero;
      }

      return Result.ok((
        playlist: Playlist(
          id: p.id,
          name: p.name,
          comment: p.comment,
          created: p.created,
          changed: p.changed,
          duration: duration,
          songCount: songs.length,
          coverId: p.coverArt,
        ),
        tracks: songs
      ));
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<void>> refresh(
      {bool forceRefresh = false, Set<String> refreshIds = const {}}) async {
    final result = await _subsonic.getPlaylists(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }

    try {
      final playlists = result.value.playlist
          .where((p) => refreshIds.isEmpty || refreshIds.contains(p.id));

      final toUpdate = <PlaylistModel>[];

      if (forceRefresh) {
        toUpdate.addAll(playlists);
      } else {
        for (var p in playlists) {
          if (await _db.managers.playlistTable
                  .filter((f) => f.id(p.id) & f.changed.isAfterOrOn(p.changed))
                  .getSingleOrNull() !=
              null) {
            continue;
          }
          toUpdate.add(p);
        }
      }

      if (toUpdate.isEmpty) return Result.ok(null);

      Map<String, List<ChildModel>> playlistSongs = {};

      final results = await Future.wait(toUpdate.map((p) async {
        final r = await _loadPlaylistSongs(p.id);
        switch (r) {
          case Err():
            return Result.error(r.error);
          case Ok():
        }
        playlistSongs[p.id] = r.value;
        return Result.ok(null);
      }));
      for (final r in results) {
        switch (r) {
          case Err():
            return Result.error(r.error);
          case Ok():
        }
      }

      await _db.transaction(() async {
        final playlistIds = playlists.map((p) => p.id);
        final toUpdateIds = toUpdate.map((p) => p.id);
        await _db.managers.playlistTable
            .filter((f) => f.id.isIn(playlistIds).not())
            .delete();
        await _db.managers.playlistSongTable
            .filter((f) => f.playlistId.id.isIn(toUpdateIds))
            .delete();

        await _db.managers.playlistTable.bulkCreate(
          (o) => toUpdate.map(
            (p) => o(
              id: p.id,
              changed: p.changed,
              created: p.created,
              durationMs: p.duration * 1000,
              name: p.name,
              songCount: p.songCount,
              comment: Value(p.comment),
              coverArt: Value(p.coverArt),
            ),
          ),
          mode: InsertMode.replace,
        );
        await Future.wait(toUpdate.map((p) async {
          final songs = (playlistSongs[p.id] ?? []);
          await _db.managers.playlistSongTable.bulkCreate(
            (o) => List.generate(
              songs.length,
              (i) => o(
                playlistId: p.id,
                songId: songs[i].id,
                childModelJson: jsonEncode(songs[i]),
                index: i,
              ),
            ),
          );
        }));
      });

      notifyListeners();
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }

  Future<Result<List<ChildModel>>> _loadPlaylistSongs(String playlistId) async {
    final result = await _subsonic.getPlaylist(_auth.con, playlistId);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        _favorites.updateAll((result.value.entry ?? []).map((c) =>
            (type: FavoriteType.song, id: c.id, favorite: c.starred != null)));
        return Result.ok(result.value.entry ?? []);
    }
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      refresh(forceRefresh: true);
    }
  }

  Uri? getPlaylistCoverUri(Playlist p) {
    if (p.coverId == null) return null;
    return _subsonic.getCoverUri(_auth.con, p.coverId!);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
