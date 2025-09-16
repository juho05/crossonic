import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

class ScanViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;

  FetchStatus _status = FetchStatus.initial;
  FetchStatus get status => _status;

  bool get supportsScanType => _subsonic.supports.scanType;

  ScanStatus _scanStatus = const (
    scanning: false,
    isFullScan: null,
    lastScan: null,
    scanStart: null,
    scanned: null
  );
  ScanStatus get scanStatus => _scanStatus;

  Timer? _refreshTimer;

  ScanViewModel({required SubsonicRepository subsonic}) : _subsonic = subsonic {
    _status = FetchStatus.loading;
    _loadStatus();
  }

  Future<Result<void>> scan(bool fullScan) async {
    _scanStatus = (
      scanning: true,
      scanned: 0,
      isFullScan: fullScan,
      lastScan: _scanStatus.lastScan,
      scanStart: DateTime.now(),
    );
    notifyListeners();
    final result = await _subsonic.startScan(fullScan: fullScan);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    _scanStatus = result.value;
    _refreshTimer ??=
        Timer.periodic(const Duration(milliseconds: 250), (timer) async {
      await _loadStatus();
    });
    notifyListeners();
    return const Result.ok(null);
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
    _scanStatus = result.value;
    if (_scanStatus.scanning) {
      _refreshTimer ??=
          Timer.periodic(const Duration(milliseconds: 250), (timer) async {
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
