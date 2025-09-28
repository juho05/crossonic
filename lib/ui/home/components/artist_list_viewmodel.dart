import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class HomeArtistListViewModel extends ChangeNotifier {
  final HomeComponentDataSource<Artist> _dataSource;

  List<Artist>? _artists;
  List<Artist> get artists => _artists ?? [];

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  StreamSubscription? _refreshStreamSub;
  HomeArtistListViewModel({
    required HomeComponentDataSource<Artist> dataSource,
    Stream? refreshStream,
  }) : _dataSource = dataSource {
    load().then(
      (_) {
        _refreshStreamSub = refreshStream?.listen((_) => load());
      },
    );
  }

  bool _loading = false;
  Future<void> load() async {
    if (_loading) return;
    _loading = true;

    if (_status != FetchStatus.success) {
      _status = FetchStatus.loading;
      _artists = null;
      notifyListeners();
    }

    final result = await _dataSource.get(20);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
      case Ok():
        _status = FetchStatus.success;
        _artists = result.value.toList();
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
