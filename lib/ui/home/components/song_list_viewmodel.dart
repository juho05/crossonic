import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeSongListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Song> _dataSource;

  List<Song>? _songs;
  List<Song> get songs => _songs ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  HomeSongListViewModel({
    required HomeComponentDataSource<Song> dataSource,
  }) : _dataSource = dataSource {
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
}
