import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeSongListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Song> _dataSource;

  List<Song>? _songs;
  List<Song> get songs => _songs ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  StreamSubscription? _refreshStreamSub;

  final HomeViewModel _homeViewModel;

  HomeSongListViewModel({
    required HomeComponentDataSource<Song> dataSource,
    Stream? refreshStream,
    required HomeViewModel homeViewModel,
  })  : _dataSource = dataSource,
        _homeViewModel = homeViewModel {
    load().then((_) {
      _refreshStreamSub = refreshStream?.listen((_) => load());
    });
  }

  bool _loading = false;
  Future<void> load() async {
    if (_loading) return;
    _loading = true;

    if (_status != FetchStatus.success) {
      _status = FetchStatus.loading;
      _songs = null;
      notifyListeners();
    }

    final result = await _dataSource.get(10, seed: _homeViewModel.seed);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _songs = result.value.toList();
    }
    notifyListeners();
    _loading = false;
  }

  @override
  void dispose() {
    _refreshStreamSub?.cancel();
    super.dispose();
  }
}
