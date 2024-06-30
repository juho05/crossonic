import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/exceptions.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:crossonic/repositories/api/models/media_model.dart';
import 'package:crossonic/repositories/api/models/playlist_model.dart';
import 'package:crossonic/services/audio_handler/offline_cache/offline_cache.dart';
import 'package:crossonic/widgets/cover_art.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistRepository {
  static const playlistIndexKey = "playlist-index";
  static const playlistDownloadsKey = "playlist-downloads";

  final APIRepository _apiRepository;
  final SharedPreferences _sharedPreferences;
  final OfflineCache _offlineCache;

  final BehaviorSubject<Map<String, bool>> playlistDownloads =
      BehaviorSubject.seeded({});

  PlaylistRepository({
    required APIRepository apiRepository,
    required SharedPreferences sharedPreferences,
    required OfflineCache offlineCache,
  })  : _apiRepository = apiRepository,
        _sharedPreferences = sharedPreferences,
        _offlineCache = offlineCache {
    _loadIndex();
    _loadDownloads();
    playlists.listen((_) async {
      await _storeIndex();
    });
    _apiRepository.authStatus.listen((status) {
      if (status == AuthStatus.unauthenticated) {
        playlists.add([]);
      } else {
        fetch();
      }
    });
  }

  void _loadIndex() {
    if (playlists.valueOrNull?.isNotEmpty ?? false) return;
    final json = _sharedPreferences.getString(playlistIndexKey);
    if (json == null) {
      playlists.add([]);
      return;
    }
    playlists.add((jsonDecode(json) as List<dynamic>)
        .map((s) => Playlist.fromJson(s))
        .toList());
  }

  void _loadDownloads() {
    if (playlistDownloads.value.isNotEmpty) return;
    final json = _sharedPreferences.getString(playlistDownloadsKey);
    if (json == null) return;
    playlistDownloads.add((jsonDecode(json) as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, value)));
  }

  Future<void> _storeIndex() async {
    if (playlists.valueOrNull?.isEmpty ?? true) {
      await _sharedPreferences.remove(playlistIndexKey);
      return;
    }
    await _sharedPreferences.setString(
        playlistIndexKey, jsonEncode(playlists.value));
  }

  Future<void> _storeDownloads() async {
    if (playlistDownloads.value.isEmpty) {
      await _sharedPreferences.remove(playlistDownloadsKey);
      return;
    }
    await _sharedPreferences.setString(
        playlistDownloadsKey, jsonEncode(playlistDownloads.value));
  }

  Future<void> downloadPlaylist(String id) async {
    if (playlistDownloads.value.containsKey(id)) return;
    final newMap = Map<String, bool>.from(playlistDownloads.value);
    newMap[id] = false;
    playlistDownloads.add(newMap);
    await _storeDownloads();
    _downloadOfflinePlaylists();
  }

  Future<void> removePlaylistDownload(String id) async {
    if (!playlistDownloads.value.containsKey(id)) return;
    final newMap = Map<String, bool>.from(playlistDownloads.value);
    newMap.remove(id);
    playlistDownloads.add(newMap);
    await _storeDownloads();
    _downloadOfflinePlaylists();
  }

  bool _downloadingSongs = false;
  bool _rerunSongDownload = false;
  Future<void> _downloadOfflinePlaylists() async {
    if (_downloadingSongs) {
      _rerunSongDownload = true;
      return;
    }
    _downloadingSongs = true;
    _rerunSongDownload = false;
    final Map<String, bool> downloaded = {};
    try {
      final downloadedSongIDs = await _offlineCache.getDownloadedSongIDs();
      print("downloading");
      final playlists = await Future.wait(playlistDownloads.value.keys
          .map((id) async => await getUpdatedPlaylist(id)));
      for (var playlist in playlists) {
        try {
          if (playlist.entry != null) {
            bool everythingDownloaded = true;
            for (var s in playlist.entry!) {
              if (!downloadedSongIDs.remove(s.id)) {
                everythingDownloaded = false;
              }
            }
            if (!everythingDownloaded) {
              await _offlineCache.download(playlist.entry!);
            }
            downloaded[playlist.id] = true;
          } else {
            downloaded[playlist.id] = false;
          }
        } catch (_) {
          downloaded[playlist.id] = false;
        }
      }
      print("removing ${downloadedSongIDs.length} songs");
      await _offlineCache.remove(downloadedSongIDs);
    } finally {
      _downloadingSongs = false;
    }
    playlistDownloads.add(downloaded);
    if (_rerunSongDownload) {
      print("rerun");
      _downloadOfflinePlaylists();
    }
    print("done");
  }

  final BehaviorSubject<List<Playlist>> playlists = BehaviorSubject();

  Future<void> fetch() async {
    try {
      final remote = await _apiRepository.getPlaylists();
      bool updateDownloads = false;
      playlists.add(await Future.wait(remote.map((p) async {
        try {
          final old = playlists.value.firstWhere((pl) => pl.id == p.id);
          if (old.entry == null) {
            return p;
          }
          if (old.changed != p.changed) {
            try {
              final remotePlaylist = await _apiRepository.getPlaylist(p.id);
              updateDownloads = true;
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
      if (updateDownloads) {
        _downloadOfflinePlaylists();
      }
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
      if (playlistDownloads.value.containsKey(id)) {
        playlistDownloads.add(Map<String, bool>.from(playlistDownloads.value)
          ..removeWhere((key, _) => key == id));
        _downloadOfflinePlaylists();
      }
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
    Playlist? playlist;
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        p.entry?.addAll(songs);
        playlist = Playlist(
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
        return playlist!;
      },
    ).toList());
    await _apiRepository.updatePlaylist(
        playlistID: id, songIDsToAdd: songs.map((s) => s.id).toList());
    await _updatePlaylist(playlist!);
  }

  Future<void> removeSongsFromPlaylist(
      String id, Iterable<(int, Media)> songs) async {
    Playlist? playlist;
    playlists.add(playlists.value.map(
      (p) {
        if (p.id != id) return p;
        for (var song in songs) {
          p.entry?.removeAt(song.$1);
        }
        playlist = Playlist(
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
        return playlist!;
      },
    ).toList());
    await _apiRepository.updatePlaylist(
        playlistID: id, trackNumbersToRemove: songs.map((s) => s.$1));
    await _updatePlaylist(playlist!);
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
      bool updateDownloads = false;
      playlists.add(playlists.value.map(
        (p) {
          if (p.id == playlist.id) newPlaylist = p;
          if (p.id != playlist.id ||
              (p.changed == playlist.changed && p.entry != null)) return p;
          updateDownloads = true;
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
      if (updateDownloads) {
        _downloadOfflinePlaylists();
      }
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
    _downloadOfflinePlaylists();
  }
}
