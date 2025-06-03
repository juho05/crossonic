import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeAlbumListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Album> _dataSource;
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  List<Album>? _albums;
  List<Album> get albums => _albums ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  HomeAlbumListViewModel({
    required HomeComponentDataSource<Album> dataSource,
    required SubsonicRepository subsonicRepository,
    required AudioHandler audioHandler,
  })  : _dataSource = dataSource,
        _subsonic = subsonicRepository,
        _audioHandler = audioHandler {
    load();
  }

  Future<void> load() async {
    _status = FetchStatus.loading;
    _albums = null;
    notifyListeners();

    final result = await _dataSource.get(15);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _albums = result.value.toList();
    }
    notifyListeners();
  }

  Future<Result<void>> play(Album album, {bool shuffle = false}) async {
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

  Future<Result<void>> addToQueue(Album album, bool priority) async {
    final result = await _subsonic.getAlbumSongs(album);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _audioHandler.queue.addAll(result.value, priority);
    return const Result.ok(null);
  }

  Future<Result<List<Song>>> getAlbumSongs(Album album) async {
    return await _subsonic.getAlbumSongs(album);
  }
}
