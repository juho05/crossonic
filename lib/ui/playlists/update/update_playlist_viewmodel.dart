import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class UpdatePlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;

  final String _playlistId;

  String _oldName = "";
  String get oldName => _oldName;
  String _oldDescription = "";
  String get oldDescription => _oldDescription;

  bool _loading = false;
  bool get loading => _loading;

  UpdatePlaylistViewModel({
    required PlaylistRepository playlistRepository,
    required String playlistId,
  })  : _repo = playlistRepository,
        _playlistId = playlistId {
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getPlaylist(_playlistId);
    switch (result) {
      case Err():
        Log.error("Failed to load playlist to update.", e: result.error);
        return;
      case Ok():
    }
    if (result.value == null) {
      Log.error("Playlist to update does not exist.");
      return;
    }
    _oldName = result.value!.playlist.name;
    _oldDescription = result.value!.playlist.comment ?? "";
  }

  Future<Result<void>> update(String name, String description) async {
    _loading = true;
    notifyListeners();
    try {
      return await _repo.updatePlaylistMetadata(
        _playlistId,
        name: name,
        comment: description,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
