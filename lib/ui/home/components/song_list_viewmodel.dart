import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeSongListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Song> _dataSource;
  final AudioHandler _audioHandler;

  List<Song>? _songs;
  List<Song> get songs => _songs ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  HomeSongListViewModel({
    required HomeComponentDataSource<Song> dataSource,
    required AudioHandler audioHandler,
  })  : _dataSource = dataSource,
        _audioHandler = audioHandler {
    load();
  }

  Future<void> load() async {
    _status = FetchStatus.loading;
    _songs = null;
    notifyListeners();

    final result = await _dataSource.get(10);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _songs = result.value.toList();
    }
    notifyListeners();
  }

  Future<void> play(int songIndex, bool single) async {
    if (status != FetchStatus.success) return;
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([songs[songIndex]]);
    } else {
      _audioHandler.queue.replace(songs, songIndex);
    }
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.queue.add(song, priority);
  }
}
