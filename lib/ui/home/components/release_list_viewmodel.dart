import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeReleaseListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Album> _dataSource;

  List<Album>? _albums;
  List<Album> get albums => _albums ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  HomeReleaseListViewModel({
    required HomeComponentDataSource<Album> dataSource,
  }) : _dataSource = dataSource {
    load();
  }

  Future<void> load() async {
    _status = FetchStatus.loading;
    _albums = null;
    notifyListeners();

    final result = await _dataSource.get(20);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _albums = result.value.toList();
    }
    notifyListeners();
  }
}
