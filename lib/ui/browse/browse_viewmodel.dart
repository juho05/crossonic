import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class BrowseViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  bool _searchMode = false;
  bool get searchMode => _searchMode;

  FetchStatus _searchStatus = FetchStatus.initial;
  FetchStatus get searchStatus => _searchStatus;

  List<Song> _songs = [];
  List<Song> get songs => _songs;

  List<Album> _albums = [];
  List<Album> get albums => _albums;

  List<Artist> _artists = [];
  List<Artist> get artists => _artists;

  BrowseViewModel({
    required SubsonicRepository subsonicRepository,
  }) : _subsonic = subsonicRepository;

  Future<void> updateSearchText(String search,
      {bool disableDebounce = false}) async {
    _songs = [];
    _albums = [];
    _artists = [];

    if (search.isEmpty) {
      _searchMode = false;
      _searchStatus = FetchStatus.initial;
      notifyListeners();
      return;
    }

    _searchMode = true;
    _searchStatus = FetchStatus.loading;
    notifyListeners();

    final result = await _subsonic.search(search,
        artistCount: 3, albumCount: 5, songCount: 15);
    switch (result) {
      case Err():
        _searchStatus = FetchStatus.failure;
      case Ok():
        _searchStatus = FetchStatus.success;
        _songs = result.value.songs.toList();
        _albums = result.value.albums.toList();
        _artists = result.value.artists.toList();
    }
    notifyListeners();
  }
}
