import 'dart:collection';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

typedef SongLoader = Future<Result<Iterable<Song>>> Function();

class AddToPlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repository;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Iterable<Song> _songs = [];
  Iterable<Song> get songs => _songs;
  int get songCount => _songs.length;

  List<Playlist> _playlists = [];
  List<Playlist> _filteredPlaylists = [];
  List<Playlist> get playlists => _filteredPlaylists;

  final Set<Playlist> _selectedPlaylists = {};
  Set<Playlist> get selectedPlaylists => _selectedPlaylists;

  Map<String, int> _songInPlaylistCounts = {};
  Map<String, int> get songInPlaylistCounts => _songInPlaylistCounts;

  String _query = "";

  AddToPlaylistViewModel(
      {required PlaylistRepository repository, required SongLoader songLoader})
      : _repository = repository {
    _load(songLoader);
    _repository.addListener(_onPlaylistsChanged);
  }

  Future<void> _load(SongLoader loader) async {
    _status = FetchStatus.loading;
    notifyListeners();
    final results = await Future.wait([
      _loadSongs(loader),
      _loadPlaylists(),
    ]);

    if (results.any((r) => r is Err)) {
      _status = FetchStatus.failure;
      notifyListeners();
      return;
    }

    _status = FetchStatus.success;
    notifyListeners();

    if (_songs.length == 1) {
      await _loadSongInPlaylistCounts(_songs.first);
    }

    _repository.refresh();
  }

  Future<Result<void>> _loadSongs(SongLoader loader) async {
    final result = await loader();
    switch (result) {
      case Err():
        _songs = [];
        return Result.error(result.error);
      case Ok():
        _songs = result.value;
    }
    return const Result.ok(null);
  }

  Future<Result<void>> _loadPlaylists() async {
    final result =
        await _repository.getPlaylists(orderBy: PlaylistOrderBy.updated);
    switch (result) {
      case Err():
        _playlists = [];
        return Result.error(result.error);
      case Ok():
        _playlists = result.value;
    }
    _updateFilteredPlaylists();
    return const Result.ok(null);
  }

  Future<void> _loadSongInPlaylistCounts(Song song) async {
    final result = await _repository.getCountOfSongInPlaylists(song.id);
    switch (result) {
      case Err():
        _songInPlaylistCounts = {};
        Log.error("Failed to load song in playlist counts.", e: result.error);
      case Ok():
        _songInPlaylistCounts = result.value;
    }
    notifyListeners();
  }

  void toggleSelection(Playlist playlist) {
    if (_selectedPlaylists.contains(playlist)) {
      _selectedPlaylists.remove(playlist);
    } else {
      _selectedPlaylists.add(playlist);
    }
    notifyListeners();
  }

  void search(String query) {
    _query = query.trim().toLowerCase();
    _updateFilteredPlaylists();
    notifyListeners();
  }

  Future<int> addSongsToPlaylists(
      Future<bool?> Function(Playlist p, Song s) askDuplicate) async {
    int successCount = 0;
    selectedPlaylistsLoop:
    for (final p in _selectedPlaylists) {
      if (_songs.length == 1) {
        final result = await _repository.addTracks(p.id, _songs);
        if (result is Err) {
          Log.error("Failed to add song to playlist.", e: result.error);
          continue;
        }
        successCount++;
        continue;
      }

      final result = await _repository.getTrackIdsInPlaylist(p.id);
      switch (result) {
        case Err():
          Log.error("Failed to get track IDs of playlist.", e: result.error);
          continue;
        case Ok():
      }
      if (result.value == null) continue;
      Queue<Song> add = DoubleLinkedQueue();
      for (final s in _songs) {
        if (result.value!.contains(s.id)) {
          final include = await askDuplicate(p, s);
          if (include == null) {
            continue selectedPlaylistsLoop;
          }
          if (!include) {
            continue;
          }
        }
        add.add(s);
      }
      if (add.isNotEmpty) {
        final addResult = await _repository.addTracks(p.id, add);
        if (addResult is Err) {
          Log.error("Failed to add tracks to playlist.", e: addResult.error);
          continue;
        }
      }
      successCount++;
    }
    return successCount;
  }

  void _updateFilteredPlaylists() {
    if (_query.isEmpty) {
      _filteredPlaylists = _playlists;
      return;
    }
    _filteredPlaylists =
        _playlists.where((p) => p.name.toLowerCase().contains(_query)).toList();
  }

  Future<void> _onPlaylistsChanged() async {
    await _loadPlaylists();
    if (_songs.length == 1) {
      await _loadSongInPlaylistCounts(_songs.first);
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onPlaylistsChanged);
    super.dispose();
  }

  Future<void> removeSongFromPlaylist(Playlist p) async {
    if (_songs.length != 1) return;
    await _repository.removeLastOccurrenceOfTrack(p.id, _songs.first.id);
    _songInPlaylistCounts[p.id] = _songInPlaylistCounts[p.id]! - 1;
    notifyListeners();
  }
}
