import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeArtistListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Artist> _dataSource;
  final SubsonicRepository _subsonic;
  final AudioHandler _audioHandler;

  List<Artist>? _artists;
  List<Artist> get artists => _artists ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  HomeArtistListViewModel({
    required HomeComponentDataSource<Artist> dataSource,
    required SubsonicRepository subsonicRepository,
    required AudioHandler audioHandler,
  })  : _dataSource = dataSource,
        _subsonic = subsonicRepository,
        _audioHandler = audioHandler {
    load();
  }

  Future<void> load() async {
    _status = FetchStatus.loading;
    _artists = null;
    notifyListeners();

    final result = await _dataSource.get(20);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _artists = result.value.toList();
    }
    notifyListeners();
  }

  Future<Result<void>> play(Artist artist,
      {bool shuffleAlbums = false, bool shuffleSongs = false}) async {
    return _subsonic.incrementallyLoadArtistSongs(artist,
        (songs, firstBatch) async {
      if (firstBatch) {
        _audioHandler.playOnNextMediaChange();
        _audioHandler.queue.replace(songs);
        return;
      }
      _audioHandler.queue.addAll(songs, false);
    }, shuffleReleases: shuffleAlbums, shuffleSongs: shuffleSongs);
  }

  Future<Result<void>> addToQueue(Artist artist, bool priority) async {
    return _subsonic.incrementallyLoadArtistSongs(
      artist,
      (songs, firstBatch) async => _audioHandler.queue.addAll(songs, priority),
    );
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
}
