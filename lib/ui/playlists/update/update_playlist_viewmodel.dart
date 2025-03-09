import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class UpdatePlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;

  final String _playlistId;

  bool _loading = false;
  bool get loading => _loading;

  UpdatePlaylistViewModel({
    required PlaylistRepository playlistRepository,
    required String playlistId,
  })  : _repo = playlistRepository,
        _playlistId = playlistId;

  Future<Result<void>> update(String name) async {
    _loading = true;
    notifyListeners();
    try {
      return await _repo.updatePlaylistMetadata(_playlistId, name: name);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
