import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class CreatePlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;

  bool _loading = false;
  bool get loading => _loading;

  CreatePlaylistViewModel({
    required PlaylistRepository playlistRepository,
  }) : _repo = playlistRepository;

  Future<Result<String>> create(String name) async {
    _loading = true;
    notifyListeners();
    try {
      return await _repo.create(name);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
