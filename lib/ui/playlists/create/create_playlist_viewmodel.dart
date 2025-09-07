import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class CreatePlaylistViewModel extends ChangeNotifier {
  final PlaylistRepository _repo;

  bool _loading = false;
  bool get loading => _loading;

  CreatePlaylistViewModel({
    required PlaylistRepository playlistRepository,
  }) : _repo = playlistRepository;

  Future<Result<String>> create(String name,
      {Iterable<Song> songs = const []}) async {
    _loading = true;
    notifyListeners();
    try {
      final result = await _repo.create(name);
      switch (result) {
        case Err():
          return result;
        case Ok():
      }
      if (songs.isNotEmpty) {
        final addResult = await _repo.addTracks(result.value, songs);
        switch (addResult) {
          case Err():
            Log.error("Failed to add initial tracks to created playlist.",
                e: addResult.error);
          case Ok():
        }
      }
      return result;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
