import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeReleaseListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Album> _dataSource;

  List<Album>? _albums;
  List<Album> get albums => _albums ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  StreamSubscription? _refreshStreamSub;

  final HomeViewModel _homeViewModel;

  HomeReleaseListViewModel({
    Stream? refreshStream,
    required HomeComponentDataSource<Album> dataSource,
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
      _albums = null;
      notifyListeners();
    }

    final result = await _dataSource.get(20, seed: _homeViewModel.seed);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _albums = result.value.toList();
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
