import 'dart:async';

import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class BrowseViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  final BehaviorSubject<bool> _emptySearchStream = BehaviorSubject.seeded(true);
  ValueStream<bool> get emptySearchStream => _emptySearchStream.stream;

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
    required AudioHandler audioHandler,
  })  : _subsonic = subsonicRepository,
        _audioHandler = audioHandler;

  Timer? _searchDebounce;
  void updateSearchText(String search) {
    if (_emptySearchStream.value != search.isEmpty) {
      _emptySearchStream.add(search.isEmpty);
    }
    _searchDebounce?.cancel();
    if (search.isEmpty) {
      _searchMode = false;
      _searchStatus = FetchStatus.initial;
      _songs = [];
      _albums = [];
      _artists = [];
      notifyListeners();
      return;
    }
    _searchDebounce = Timer(
        const Duration(milliseconds: 500), () => _updateSearchText(search));
  }

  Future<Result<void>> playArtist(
    Artist artist, {
    bool shuffleAlbums = false,
    bool shuffleSongs = false,
  }) async {
    final result = await _subsonic.getArtistSongs(artist);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    if (shuffleAlbums) {
      result.value.shuffle();
    }
    final songs = result.value.expand((e) => e).toList();
    if (shuffleSongs) {
      songs.shuffle();
    }
    _audioHandler.playOnNextMediaChange();
    _audioHandler.queue.replace(songs);
    return const Result.ok(null);
  }

  Future<Result<void>> addArtistToQueue(Artist artist, bool priority) async {
    final result = await _subsonic.getArtistSongs(artist);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value.expand((e) => e), priority);
    return const Result.ok(null);
  }

  Future<Result<void>> playAlbum(Album album, {bool shuffle = false}) async {
    final result = await _subsonic.getAlbumSongs(album);
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
    return const Result.ok(null);
  }

  Future<Result<void>> addAlbumToQueue(Album album, bool priority) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return const Result.ok(null);
  }

  void playSong(int index, bool single) {
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([songs[index]]);
    } else {
      _audioHandler.queue.replace(songs, index);
    }
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }

  Future<void> _updateSearchText(String search) async {
    _searchMode = true;
    _searchStatus = FetchStatus.loading;
    _songs = [];
    _albums = [];
    _artists = [];
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

  Future<Result<List<Song>>> getAlbumSongs(Album album) async {
    return await _subsonic.getAlbumSongs(album);
  }

  Future<Result<List<Song>>> getArtistSongs(Artist artist) async {
    final result = await _subsonic.getArtistSongs(artist);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
        return Result.ok(result.value.expand((l) => l).toList());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _emptySearchStream.close();
    super.dispose();
  }
}
