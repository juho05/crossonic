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
  downloaded,
}

class PlaylistsViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;
  final AudioHandler _audioHandler;
  final SongDownloader _downloader;

  List<(Playlist, DownloadStatus)> _playlists = [];
  List<(Playlist, DownloadStatus)> get playlists => _playlists;

  PlaylistsSort _sort = PlaylistsSort.updated;
  PlaylistsSort get sort => _sort;
  set sort(PlaylistsSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _sortPlaylists();
    notifyListeners();
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
    _sortPlaylists();
    notifyListeners();
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

  void _sortPlaylists() {
    if (sort == PlaylistsSort.random) {
      _playlists.shuffle();
      return;
    }
    switch (sort) {
      case PlaylistsSort.updated || PlaylistsSort.downloaded:
        _playlists.sort((a, b) => b.$1.changed.compareTo(a.$1.changed));
      case PlaylistsSort.created:
        _playlists.sort((a, b) => b.$1.created.compareTo(a.$1.created));
      case PlaylistsSort.alphabetical:
        _playlists.sort((a, b) => a.$1.name.compareTo(b.$1.name));
      case PlaylistsSort.songCount:
        _playlists.sort((a, b) => b.$1.songCount.compareTo(a.$1.songCount));
      case PlaylistsSort.duration:
        _playlists.sort((a, b) => b.$1.duration.compareTo(a.$1.duration));
      case PlaylistsSort.random:
        // shouldn't happen
        break;
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
