import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/api/models/playlist_model.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:rxdart/rxdart.dart';

class PlaylistRepository {
  final APIRepository _apiRepository;

  PlaylistRepository({required APIRepository apiRepository})
      : _apiRepository = apiRepository {
    _apiRepository.authStatus.listen((status) {
      if (status == AuthStatus.unauthenticated) {
        playlists.add([]);
      } else {
        fetch();
      }
    });
  }

  final BehaviorSubject<List<Playlist>> playlists = BehaviorSubject.seeded([]);

  Future<void> fetch() async {
    try {
      final remote = await _apiRepository.getPlaylists();
      playlists.add(await Future.wait(remote.map((p) async {
        try {
          final old = playlists.value.firstWhere((pl) => pl.id == p.id);
          if (old.entry == null) {
            return p;
          }
          if (old.changed != p.changed) {
            try {
              final remotePlaylist = await _apiRepository.getPlaylist(p.id);
              return remotePlaylist;
            } catch (_) {}
          }
          return Playlist(
            id: p.id,
            allowedUser: p.allowedUser,
            changed: p.changed,
            comment: p.comment,
            coverArt: p.coverArt,
            created: p.created,
            duration: p.duration,
            entry: old.entry,
            name: p.name,
            owner: p.owner,
            public: p.public,
            songCount: p.songCount,
          );
        } on StateError {
          return p;
        }
      }).toList()));
    } catch (e) {
      print(e);
    }
  }

  Future<void> setPlaylistCover(String id, String ext, Uint8List cover) async {
    await _apiRepository.setPlaylistCover(id, ext, cover);
    await Future.wait([
      CachedNetworkImage.evictFromCache(
          _apiRepository.getCoverArtURL(coverArtID: id).toString()),
      CachedNetworkImage.evictFromCache(_apiRepository
          .getCoverArtURL(
              coverArtID: id, size: const CoverResolution.extraLarge().size)
          .toString()),
      CachedNetworkImage.evictFromCache(_apiRepository
          .getCoverArtURL(
              coverArtID: id, size: const CoverResolution.large().size)
          .toString()),
      CachedNetworkImage.evictFromCache(_apiRepository
          .getCoverArtURL(
              coverArtID: id, size: const CoverResolution.medium().size)
          .toString()),
      CachedNetworkImage.evictFromCache(_apiRepository
          .getCoverArtURL(
              coverArtID: id, size: const CoverResolution.small().size)
          .toString()),
      CachedNetworkImage.evictFromCache(_apiRepository
          .getCoverArtURL(
              coverArtID: id, size: const CoverResolution.tiny().size)
          .toString()),
    ]);
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        return Playlist(
          id: p.id,
          allowedUser: p.allowedUser,
          changed: p.changed,
          comment: p.comment,
          coverArt: cover.isNotEmpty ? id : null,
          created: p.created,
          duration: p.duration,
          entry: p.entry,
          name: p.name,
          owner: p.owner,
          public: p.public,
          songCount: p.songCount,
        );
      },
    ).toList());
  }

  Future<void> delete(String id) async {
    try {
      playlists.add(
          List<Playlist>.from(playlists.value)..removeWhere((p) => p.id == id));
      await _apiRepository.deletePlaylist(id);
    } finally {
      await fetch();
    }
  }

  Future<void> moveTrackInPlaylist(
      String id, int oldIndex, int newIndex) async {
    final playlist = playlists.value.firstWhere((p) => p.id == id);
    final songs = List<Media>.from(playlist.entry!);
    final song = songs.removeAt(oldIndex);
    songs.insert(oldIndex < newIndex ? newIndex - 1 : newIndex, song);
    await _uploadPlaylistTracks(id, songs.map((s) => s.id));
  }

  Future<void> addSongsToPlaylist(String id, Iterable<Media> songs) async {
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        p.entry?.addAll(songs);
        return Playlist(
          id: p.id,
          allowedUser: p.allowedUser,
          changed: p.changed,
          comment: p.comment,
          coverArt: p.coverArt,
          created: p.created,
          duration: p.duration +
              songs.fold(
                0,
                (duration, song) => duration + (song.duration ?? 0),
              ),
          entry: p.entry,
          name: p.name,
          owner: p.owner,
          public: p.public,
          songCount: p.songCount + songs.length,
        );
      },
    ).toList());
    await _apiRepository.updatePlaylist(
        playlistID: id, songIDsToAdd: songs.map((s) => s.id).toList());
    await fetch();
  }

  Future<void> removeSongsFromPlaylist(
      String id, Iterable<(int, Media)> songs) async {
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        for (var song in songs) {
          p.entry?.removeAt(song.$1);
        }
        return Playlist(
          id: p.id,
          allowedUser: p.allowedUser,
          changed: p.changed,
          comment: p.comment,
          coverArt: p.coverArt,
          created: p.created,
          duration: p.duration -
              songs.fold(
                0,
                (duration, song) => duration + (song.$2.duration ?? 0),
              ),
          entry: p.entry,
          name: p.name,
          owner: p.owner,
          public: p.public,
          songCount: p.songCount - songs.length,
        );
      },
    ).toList());
    await _apiRepository.updatePlaylist(
        playlistID: id, trackNumbersToRemove: songs.map((s) => s.$1));
    await fetch();
  }

  Playlist getPlaylistThenUpdate(String id) {
    final playlist = playlists.value.firstWhere((p) => p.id == id);
    _updatePlaylist(playlist);
    return playlist;
  }

  Future<Playlist> getUpdatedPlaylist(String id) async {
    final playlist = playlists.value.firstWhere((p) => p.id == id);
    try {
      final p = await _updatePlaylist(playlist);
      return p!;
    } on ServerUnreachableException {
      return playlist;
    } catch (e) {
      rethrow;
    }
  }

  Future<Playlist?> _updatePlaylist(Playlist playlist) async {
    try {
      final remotePlaylist = await _apiRepository.getPlaylist(playlist.id);
      Playlist? newPlaylist;
      playlists.add(playlists.value.map(
        (p) {
          if (p.id == playlist.id) newPlaylist = p;
          if (p.id != playlist.id ||
              (p.changed == playlist.changed && p.entry != null)) return p;
          final pl = Playlist(
            id: p.id,
            allowedUser: remotePlaylist.allowedUser,
            changed: remotePlaylist.changed,
            comment: remotePlaylist.comment,
            coverArt: remotePlaylist.coverArt,
            created: remotePlaylist.created,
            duration: remotePlaylist.duration,
            entry: remotePlaylist.entry,
            name: remotePlaylist.name,
            owner: remotePlaylist.owner,
            public: remotePlaylist.public,
            songCount: remotePlaylist.songCount,
          );
          newPlaylist = pl;
          return pl;
        },
      ).toList());
      return newPlaylist;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> _uploadPlaylistTracks(
      String id, Iterable<String> songIDs) async {
    final remotePlaylist = await _apiRepository.createPlaylist(
      playlistID: id,
      songIDs: songIDs,
    );
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        return Playlist(
          id: p.id,
          allowedUser: remotePlaylist.allowedUser,
          changed: remotePlaylist.changed,
          comment: remotePlaylist.comment,
          coverArt: remotePlaylist.coverArt,
          created: remotePlaylist.created,
          duration: remotePlaylist.duration,
          entry: remotePlaylist.entry,
          name: remotePlaylist.name,
          owner: remotePlaylist.owner,
          public: remotePlaylist.public,
          songCount: remotePlaylist.songCount,
        );
      },
    ).toList());
  }
}
