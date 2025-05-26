import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
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
  final CoverRepository _coverRepository;
  final Database _db;
  final SongDownloader _songDownloader;

  bool get changeCoverSupported => _auth.serverFeatures.isCrossonic;

  PlaylistRepository({
    required SubsonicService subsonic,
    required FavoritesRepository favorites,
    required AuthRepository auth,
    required Database db,
    required CoverRepository coverRepository,
    required SongDownloader songDownloader,
  })  : _subsonic = subsonic,
        _favorites = favorites,
        _auth = auth,
        _db = db,
        _coverRepository = coverRepository,
        _songDownloader = songDownloader {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
    if (!kIsWeb) {
      addListener(() => _songDownloader.update());
    }
  }

  Future<Result<void>> setDownload(String id, bool download) async {
    try {
      final affected = await _db.managers.playlistTable
          .filter((f) => f.id(id))
          .update((o) => o(download: Value(download)));
      if (affected > 0) {
        _songDownloader.update(true);
        notifyListeners();
        if (!download) {
          Timer(Duration(seconds: 10), () => _songDownloader.update());
        }
      }
      return Result.ok(null);
    } on Exception catch (e) {
      return Result.error(e);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result<void>> setCover(String id, String ext, Uint8List cover) async {
    final result = await _subsonic.setPlaylistCover(_auth.con, id, ext, cover);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _evictCoverFromCache((await getPlaylist(id)).tryValue?.playlist.coverId);
    return await refresh(refreshIds: {id});
  }

  Future<Result<void>> delete(String id) async {
    final result = await _subsonic.deletePlaylist(_auth.con, id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    try {
      await _db.managers.playlistTable.filter((f) => f.id(id)).delete();
      notifyListeners();
      return Result.ok(null);
    } on Exception catch (e) {
      await refresh();
      return Result.error(e);
    } catch (e) {
      await refresh();
      return Result.error(Exception(e.toString()));
    }
  }

  Future<Result<String>> create(String name) async {
    final result =
        await _subsonic.createPlaylist(_auth.con, playlistName: name);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    try {
      await _db.managers.playlistTable.create((o) => o(
            id: result.value.id,
            changed: result.value.changed,
            created: result.value.created,
            durationMs: result.value.duration * 1000,
            songCount: result.value.songCount,
            name: result.value.name,
            comment: Value(result.value.comment),
            coverArt: Value(result.value.coverArt),
          ));
      notifyListeners();
    } catch (e, st) {
      Log.error("Failed to create playlist in DB", e, st);
      await refresh(refreshIds: {result.value.id});
    }
    return Result.ok(result.value.id);
  }

  Future<Result<void>> reorder(String id, int oldIndex, int newIndex) async {
    final backup = await _db.managers.playlistSongTable
        .filter((f) => f.playlistId.id.equals(id))
        .orderBy((o) => o.index.asc())
        .get();
    try {
      await _db.transaction(() async {
        final song = await _db.managers.playlistSongTable
            .filter((f) => f.playlistId.id.equals(id) & f.index(oldIndex))
            .getSingle();
        await _db.managers.playlistSongTable
            .filter((f) => f.playlistId.id.equals(id) & f.index(oldIndex))
            .delete();
        if (newIndex > oldIndex) {
          newIndex--;
          await _db.customUpdate(
            "UPDATE playlist_song SET \"index\" = \"index\" - 1 WHERE playlist_id = ? AND \"index\" > ? AND \"index\" <= ?",
            variables: [
              Variable.withString(id),
              Variable.withInt(oldIndex),
              Variable.withInt(newIndex)
            ],
            updates: {_db.playlistSongTable},
          );
        } else {
          await _db.customUpdate(
            "UPDATE playlist_song SET \"index\" = \"index\" + 1 WHERE playlist_id = ? AND \"index\" < ? AND \"index\" >= ?",
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
    } on Exception catch (e) {
      return Result.error(e);
    } finally {
      notifyListeners();
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
          throw result.error;
        case Ok():
      }
    } on Exception catch (e) {
      try {
        await _db.transaction(() async {
          await _db.managers.playlistSongTable
              .filter((f) => f.playlistId.id.equals(id))
              .delete();
          await _db.managers.playlistSongTable.bulkCreate(
              (o) => backup.map((s) => o(
                  id: Value(s.id),
                  index: s.index,
                  childModelJson: s.childModelJson,
                  songId: s.songId,
                  playlistId: s.playlistId)),
              mode: InsertMode.replace);
        });
      } on Exception catch (e, st) {
        Log.error("Failed to roll-back playlist track reorder", e, st);
      } finally {
        notifyListeners();
      }
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
                download: p.download,
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
          download: p.download,
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
      final playlists = result.value.playlist;

      final toUpdate = <PlaylistModel>[];

      if (forceRefresh) {
        toUpdate.addAll(playlists
            .where((p) => refreshIds.isEmpty || refreshIds.contains(p.id)));
      } else {
        for (var p in playlists) {
          final found = await _db.managers.playlistTable
              .filter((f) => f.id(p.id) & f.changed.isAfterOrOn(p.changed))
              .getSingleOrNull();
          if (found != null) {
            continue;
          }
          if (refreshIds.isEmpty || refreshIds.contains(p.id)) {
            toUpdate.add(p);
          }
        }
      }

      final deletedCount = await _db.managers.playlistTable
          .filter((f) => f.id.isIn(playlists.map((p) => p.id)).not())
          .delete();

      if (toUpdate.isEmpty) {
        if (deletedCount > 0) {
          notifyListeners();
        }
        return Result.ok(null);
      }

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

      final toUpdateIds = toUpdate.map((p) => p.id);

      if (toUpdate.isNotEmpty) {
        final oldCoverIds = (await _db.managers.playlistTable
                .filter((f) => f.id.isIn(toUpdateIds))
                .get())
            .asMap()
            .map((key, value) => MapEntry(value.id, value.coverArt));
        for (var p in toUpdate) {
          // TODO properly check if the cover has changed
          // this only checks whether the status of having/not having a cover has changed
          if (p.coverArt != oldCoverIds[p.id]) {
            _evictCoverFromCache(oldCoverIds[p.id]);
          }
        }
      }

      await _db.transaction(() async {
        if (toUpdate.isEmpty) return;
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
          onConflict: DoUpdate.withExcluded(
            (old, excluded) => PlaylistTableCompanion.custom(
              changed: excluded.changed,
              created: excluded.created,
              comment: excluded.comment,
              coverArt: excluded.coverArt,
              durationMs: excluded.durationMs,
              name: excluded.name,
              songCount: excluded.songCount,
            ),
          ),
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
        _favorites.updateAll((result.value.entry ?? []).map(
            (c) => (type: FavoriteType.song, id: c.id, starred: c.starred)));
        return Result.ok(result.value.entry ?? []);
    }
  }

  Future<void> _evictCoverFromCache(String? coverId) async {
    if (coverId == null) return;
    Future<void> evict(String id, int resolution) async {
      await CachedNetworkImage.evictFromCache(
        CoverRepository.getKey(id, resolution),
        cacheManager: _coverRepository,
      );
    }

    await Future.wait([
      evict(coverId, 64),
      evict(coverId, 128),
      evict(coverId, 256),
      evict(coverId, 512),
      evict(coverId, 1024),
      evict(coverId, 2048),
    ]);
  }

  void _onAuthChanged() {
    if (_auth.isAuthenticated) {
      refresh(forceRefresh: true);
    } else {
      _songDownloader.clear();
    }
  }

  Uri? getPlaylistCoverUri(Playlist p, {int? size, bool constantSalt = false}) {
    if (p.coverId == null) return null;
    return _subsonic.getCoverUri(_auth.con, p.coverId!,
        size: size, constantSalt: constantSalt);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
