import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:flutter/material.dart';

enum PlaylistsSort {
  updated,
  created,
  alphabetical,
  songCount,
  duration,
  random,
}

class PlaylistsViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;
  final AudioHandler _audioHandler;
  final SongDownloader _downloader;

  List<(Playlist, DownloadStatus)> _playlists = [];
  List<(Playlist, DownloadStatus)> _filtered = [];
  List<(Playlist, DownloadStatus)> get playlists => _filtered;

  PlaylistsSort _sort = PlaylistsSort.updated;
  PlaylistsSort get sort => _sort;
  set sort(PlaylistsSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    switch (_sort) {
      case PlaylistsSort.updated:
      case PlaylistsSort.created:
      case PlaylistsSort.songCount:
      case PlaylistsSort.duration:
        _sortAscending = false;
      case PlaylistsSort.alphabetical:
        _sortAscending = true;
      case PlaylistsSort.random:
    }
    _updateFiltered();
  }

  bool _showFilters = false;
  bool get showFilters => _showFilters;
  set showFilters(bool enable) {
    if (_showFilters == enable) return;
    _showFilters = enable;
    notifyListeners();
  }

  void clearFilters() {
    _searchTerm = "";
    _offline = false;
    _updateFiltered();
  }

  String _searchTerm = "";
  String get searchTerm => _searchTerm;
  set searchTerm(String search) {
    if (search == _searchTerm) return;
    _searchTerm = search;
    _updateFiltered();
  }

  bool _sortAscending = false;
  bool get sortAscending => _sortAscending;
  set sortAscending(bool ascending) {
    if (_sortAscending == ascending) return;
    _sortAscending = ascending;
    _updateFiltered();
  }

  bool _offline = false;
  bool get offline => _offline;
  set offline(bool offline) {
    if (_offline == offline) return;
    _offline = offline;
    _updateFiltered();
  }

  PlaylistsViewModel({
    required PlaylistRepository playlistRepository,
    required AudioHandler audioHandler,
    required SongDownloader songDownloader,
  })  : _repo = playlistRepository,
        _audioHandler = audioHandler,
        _downloader = songDownloader {
    _repo.addListener(_load);
    _downloader.addListener(_onDownloadStatusChanged);
    _load();
  }

  Throttle? _onDownloadStatusChangedThrottle;
  Future<void> _onDownloadStatusChanged() async {
    Future<void> update() async {
      bool changed = false;
      for (var i = 0; i < _playlists.length; i++) {
        final status = await _getPlaylistDownloadStatus(_playlists[i].$1);
        if (status != _playlists[i].$2) {
          changed = true;
          _playlists[i] = (_playlists[i].$1, status);
        }
      }
      if (changed) {
        notifyListeners();
      }
    }

    _onDownloadStatusChangedThrottle ??= Throttle(
      action: update,
      delay: const Duration(seconds: 3),
    );
    _onDownloadStatusChangedThrottle?.call();
  }

  Future<Result<void>> toggleDownload(Playlist playlist) async {
    final newState = !playlist.download;
    final result = _repo.setDownload(playlist.id, newState);
    if (result is Ok) {
      final index = _playlists.indexWhere((p) => p.$1.id == playlist.id);
      if (index >= 0) {
        _playlists[index] = (_playlists[index].$1, DownloadStatus.downloading);
      }
      notifyListeners();
    }
    return result;
  }

  Future<Result<void>> delete(Playlist playlist) async {
    return await _repo.delete(playlist.id);
  }

  Future<Result<void>> play(Playlist playlist, {bool shuffle = false}) async {
    final result = await getTracks(playlist.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffle) {
      result.value.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(result.value);
    return const Result.ok(null);
  }

  Future<Result<void>> addToQueue(Playlist playlist, bool priority) async {
    final result = await getTracks(playlist.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return const Result.ok(null);
  }

  Future<Result<List<Song>>> getTracks(String playlistId) async {
    await _repo.refresh(forceRefresh: true, refreshIds: {playlistId});
    final r = await _repo.getPlaylist(playlistId);
    switch (r) {
      case Err():
        return Result.error(r.error);
      case Ok():
    }
    if (r.value == null) {
      return Result.error(Exception("playlist no longer exists"));
    }
    return Result.ok(r.value!.tracks);
  }

  Future<void> _load() async {
    final result = await _repo.getPlaylists();
    switch (result) {
      case Err():
        Log.error("Failed to load playlists", e: result.error);
        _playlists = [];
        notifyListeners();
        return;
      case Ok():
    }
    _playlists = await Future.wait(result.value
        .map((p) async => (p, await _getPlaylistDownloadStatus(p)))
        .toList());
    _updateFiltered();
  }

  Future<DownloadStatus> _getPlaylistDownloadStatus(Playlist playlist) async {
    if (!playlist.download) return DownloadStatus.none;
    final result = await _repo.getPlaylist(playlist.id);
    switch (result) {
      case Err():
        Log.error("Failed to get playlist for download status",
            e: result.error);
        return DownloadStatus.downloading;
      case Ok():
    }
    if (result.value == null) return DownloadStatus.none;

    DownloadStatus status = DownloadStatus.downloaded;
    for (final t in result.value!.tracks) {
      if (!_downloader.isDownloaded(t.id)) {
        status = DownloadStatus.downloading;
        break;
      }
    }
    return status;
  }

  void _updateFiltered() {
    final lowerSearch = _searchTerm.toLowerCase();
    _filtered = _playlists.where((p) {
      if (_offline && p.$2 == DownloadStatus.none) {
        return false;
      }
      if (lowerSearch.isNotEmpty &&
          !p.$1.name.toLowerCase().contains(lowerSearch)) {
        return false;
      }
      return true;
    }).toList();
    if (sort == PlaylistsSort.random) {
      _filtered.shuffle();
      notifyListeners();
      return;
    }
    _filtered.sort((a, b) => _comparePlaylists(a.$1, b.$1));
    notifyListeners();
  }

  int _comparePlaylists(Playlist a, Playlist b) {
    if (!_sortAscending) {
      final temp = a;
      a = b;
      b = temp;
    }
    switch (sort) {
      case PlaylistsSort.updated:
        return a.changed.compareTo(b.changed);
      case PlaylistsSort.created:
        return a.created.compareTo(b.created);
      case PlaylistsSort.alphabetical:
        return a.name.compareTo(b.name);
      case PlaylistsSort.songCount:
        return a.songCount.compareTo(b.songCount);
      case PlaylistsSort.duration:
        return a.duration.compareTo(b.duration);
      case PlaylistsSort.random:
        return 0;
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    _onDownloadStatusChangedThrottle?.cancel();
    _downloader.removeListener(_onDownloadStatusChanged);
    super.dispose();
  }
}
