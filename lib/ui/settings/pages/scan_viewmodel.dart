import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ScanViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  int? _scannedCount = 0;
  int? get scannedCount => _scannedCount;

  bool _scanning = false;
  bool get scanning => _scanning;

  Timer? _refreshTimer;

  ScanViewModel({required SubsonicRepository subsonic}) : _subsonic = subsonic {
    _status = FetchStatus.loading;
    _loadStatus();
  }

  Future<Result<void>> scan() async {
    _scanning = true;
    _scannedCount = 0;
    notifyListeners();
    final result = await _subsonic.startScan();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _scanning = result.value.scanning;
    _scannedCount = result.value.scanned ?? 0;
    _refreshTimer ??=
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await _loadStatus();
    });
    notifyListeners();
    return Result.ok(null);
  }

  Future<void> _loadStatus() async {
    notifyListeners();
    final result = await _subsonic.getScanStatus();
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _status = FetchStatus.success;
    _scanning = result.value.scanning;
    _scannedCount = result.value.scanned;
    if (_scanning) {
      _refreshTimer ??=
          Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        await _loadStatus();
      });
    } else {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
