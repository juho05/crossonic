import 'dart:typed_data';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImageTooLargeException extends AppException {
  ImageTooLargeException() : super("Image too large");
}

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

  bool get changeCoverSupported => _repo.changeCoverSupported;

  bool _uploadingCover = false;
  bool get uploadingCover => _uploadingCover;

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

  Future<Result<void>> toggleDownload() async {
    return _repo.setDownload(_playlistId, !_playlist!.download);
  }

  Future<Result<void>> changeCover() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return Result.ok(null);
    }
    final file = result.files[0];
    if (file.size > 15e6) {
      return Result.error(ImageTooLargeException());
    }
    _uploadingCover = true;
    notifyListeners();
    final r =
        await _repo.setCover(_playlistId, file.extension ?? "", file.bytes!);
    _uploadingCover = false;
    notifyListeners();
    return r;
  }

  Future<Result<void>> removeCover() async {
    _uploadingCover = true;
    notifyListeners();
    final result = await _repo.setCover(_playlistId, "", Uint8List(0));
    _uploadingCover = false;
    notifyListeners();
    return result;
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

  void play([int index = 0, bool single = false]) {
    if (tracks.isEmpty) {
      _audioHandler.queue.clear(priorityQueue: false);
      return;
    }
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([tracks[index]]);
    } else {
      _audioHandler.queue.replace(tracks, index);
    }
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
