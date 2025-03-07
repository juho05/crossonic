import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class PlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;
  final AudioHandler _audioHandler;

  final String _playlistId;

  Playlist? _playlist;
  Playlist? get playlist => _playlist;

  List<Song> _tracks = [];
  List<Song> get tracks => _tracks;

  bool _reorderEnabled = false;
  bool get reorderEnabled => _reorderEnabled;
  set reorderEnabled(bool enable) {
    _reorderEnabled = enable;
    notifyListeners();
  }

  PlaylistViewModel({
    required PlaylistRepository playlistRepository,
    required AudioHandler audioHandler,
    required String playlistId,
  })  : _repo = playlistRepository,
        _audioHandler = audioHandler,
        _playlistId = playlistId {
    _repo.addListener(_load);
    _load();
    _repo.refresh(forceRefresh: true, refreshIds: {_playlistId});
  }

  Future<void> _load() async {
    final result = await _repo.getPlaylist(_playlistId);
    switch (result) {
      case Err():
        _playlist = null;
        print(result.error);
      case Ok():
        if (result.value == null) {
          _playlist = null;
          print("playlist does not exist");
        }
        _playlist = result.value!.playlist;
        _tracks = result.value!.tracks;
    }
    notifyListeners();
  }

  void play([int index = 0]) {
    if (tracks.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(tracks, index);
  }

  void shuffle() {
    if (tracks.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(List.of(tracks)..shuffle());
  }

  void addToQueue(bool priority) {
    if (tracks.isEmpty) return;
    _audioHandler.queue.addAll(tracks, priority);
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  Future<Result<void>> remove(int index) async {
    tracks.removeAt(index);
    notifyListeners();
    return await _repo.removeTrack(_playlistId, index);
  }

  Future<Result<void>> reorder(int oldIndex, int newIndex) async {
    final s = tracks.removeAt(oldIndex);
    if (oldIndex < newIndex) {
      tracks.insert(newIndex - 1, s);
    } else {
      tracks.insert(newIndex, s);
    }
    notifyListeners();
    return await _repo.reorder(_playlistId, oldIndex, newIndex);
  }

  @override
  void dispose() {
    _repo.removeListener(_load);
    super.dispose();
  }
}
