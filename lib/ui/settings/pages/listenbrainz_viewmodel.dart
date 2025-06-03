import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ListenBrainzViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  String? _username;
  String? get username => _username;

  bool _submitting = false;
  bool get submitting => _submitting;

  ListenBrainzViewModel({required SubsonicRepository subsonicRepository})
      : _subsonic = subsonicRepository;

  Future<void> load() async {
    _status = FetchStatus.loading;
    _username = null;
    _submitting = false;
    notifyListeners();
    final result = await _subsonic.getListenBrainzConfig();
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _username = result.value.username;
    _status = FetchStatus.success;
    notifyListeners();
  }

  Future<Result<void>> connect(String apiToken) async {
    _submitting = true;
    notifyListeners();
    final result = await _subsonic.connectListenBrainz(apiToken);
    _submitting = false;
    switch (result) {
      case Err():
        notifyListeners();
        return Result.error(result.error);
      case Ok():
    }
    _username = result.value.username;
    notifyListeners();
    return const Result.ok(null);
  }

  Future<Result<void>> disconnect() async {
    _submitting = true;
    notifyListeners();
    final result = await _subsonic.disconnectListenBrainz();
    _submitting = false;
    switch (result) {
      case Err():
        notifyListeners();
        return Result.error(result.error);
      case Ok():
    }
    _username = result.value.username;
    notifyListeners();
    return const Result.ok(null);
  }
}
