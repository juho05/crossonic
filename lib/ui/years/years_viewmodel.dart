import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class YearsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  int _fromYear;
  int get fromYear => _fromYear;
  set fromYear(int year) {
    _toYear += year - _fromYear;
    _fromYear = year;
    _status = FetchStatus.initial;
    _fetch(0);
  }

  int _toYear;
  int get toYear => _toYear;
  set toYear(int year) {
    _toYear = year;
    _status = FetchStatus.initial;
    _fetch(0);
  }

  YearsViewModel({required SubsonicRepository subsonic})
      : _fromYear = DateTime.now().year - 10,
        _toYear = DateTime.now().year,
        _subsonic = subsonic;

  static final int _pageSize = 100;

  final List<Album> albums = [];

  bool _reachedEnd = false;
  int get _nextPage => (albums.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  Future<void> nextPage() async {
    if (_reachedEnd) return;
    return await _fetch(_nextPage);
  }

  Future<void> _fetch(int page) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;
    if (page * _pageSize < albums.length) {
      albums.removeRange(page * _pageSize, albums.length);
    }
    notifyListeners();
    final result = await _subsonic.getAlbumsByYears(
        fromYear, toYear, _pageSize, page * _pageSize);
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _status = FetchStatus.success;
    _reachedEnd = result.value.length < _pageSize;
    albums.addAll(result.value);
    notifyListeners();
  }
}
