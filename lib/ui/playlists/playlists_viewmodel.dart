import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
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

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

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
  })  : _repo = playlistRepository,
        _audioHandler = audioHandler {
    _repo.addListener(_load);
    _load();
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
    return Result.ok(null);
  }

  Future<Result<void>> addToQueue(Playlist playlist, bool priority) async {
    final result = await getTracks(playlist.id);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return Result.ok(null);
  }

  Future<Result<List<Song>>> getTracks(String playlistId) async {
    final result =
        await _repo.refresh(forceRefresh: true, refreshIds: {playlistId});
    switch (result) {
      case Err():
        if (result.error is! ConnectionException) {
          print(result.error);
        }
      case Ok():
    }
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
        print(result.error);
        _playlists = [];
        notifyListeners();
        return;
      case Ok():
    }
    _playlists = result.value;
    _sortPlaylists();
    notifyListeners();
  }

  void _sortPlaylists() {
    if (sort == PlaylistsSort.random) {
      _playlists.shuffle();
      return;
    }
    switch (sort) {
      case PlaylistsSort.updated:
        _playlists.sort((a, b) => b.changed.compareTo(a.changed));
      case PlaylistsSort.created:
        _playlists.sort((a, b) => b.created.compareTo(a.created));
      case PlaylistsSort.alphabetical:
        _playlists.sort((a, b) => a.name.compareTo(b.name));
      case PlaylistsSort.songCount:
        _playlists.sort((a, b) => b.songCount.compareTo(a.songCount));
      case PlaylistsSort.duration:
        _playlists.sort((a, b) => b.duration.compareTo(a.duration));
      case PlaylistsSort.random:
        // shouldn't happen
        break;
    }
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    super.dispose();
  }
}
