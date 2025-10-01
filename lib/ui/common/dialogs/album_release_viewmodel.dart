import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class AlbumReleaseDialogViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  final Album _album;
  Album get album => _album;

  List<Album> _alternatives;
  List<Album> get alternatives => _alternatives;

  FetchStatus _status;
  FetchStatus get status => _status;

  AlbumReleaseDialogViewModel(
      {required SubsonicRepository subsonicRepository,
      required Album album,
      List<Album>? alternatives})
      : _subsonic = subsonicRepository,
        _album = album,
        _alternatives = alternatives ?? const [],
        _status =
            alternatives != null ? FetchStatus.success : FetchStatus.initial {
    if (alternatives == null) {
      _loadAlternatives();
    } else {
      _sortAlternatives();
    }
  }

  Future<void> _loadAlternatives() async {
    if (!_subsonic.supports.getAlternateAlbumVersions) {
      _status = FetchStatus.success;
      notifyListeners();
      return;
    }

    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.getAlternateAlbumVersions(album.id);
    switch (result) {
      case Err():
        Log.error("failed to load album alternatives", e: result.error);
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }

    _alternatives = result.value.toList();
    _sortAlternatives();
    _status = FetchStatus.success;
    notifyListeners();
  }

  void _sortAlternatives() {
    if (_alternatives.isEmpty) return;
    _alternatives.sort((a, b) {
      if (a.releaseDate != null && b.releaseDate != null) {
        return a.releaseDate!.compareTo(b.releaseDate!);
      }
      if (a.releaseDate != null) {
        return -1;
      }
      if (b.releaseDate != null) {
        return 1;
      }
      if (a.version != null && b.version != null) {
        return a.version!.compareTo(b.version!);
      }
      if (a.version != null) {
        return -1;
      }
      if (b.version != null) {
        return 1;
      }
      return a.id.compareTo(b.id);
    });
  }
}
