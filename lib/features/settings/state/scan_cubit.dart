import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:equatable/equatable.dart';

part 'scan_state.dart';

class ScanCubit extends Cubit<ScanState> {
  final APIRepository _apiRepository;

  Timer? _refreshTimer;

  ScanCubit({required APIRepository apiRepository})
      : _apiRepository = apiRepository,
        super(const ScanState(
            loadingStatus: true, scannedCount: null, scanning: false)) {
    _getScanStatus();
  }

  Future<void> rescan() async {
    final status = await _apiRepository.startScan();
    emit(ScanState(scannedCount: status.count ?? 0, scanning: status.scanning));
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _getScanStatus();
    });
  }

  Future<void> _getScanStatus() async {
    final status = await _apiRepository.getScanStatus();
    emit(ScanState(scannedCount: status.count, scanning: status.scanning));
    if (!status.scanning) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else {
      _refreshTimer ??=
          Timer.periodic(const Duration(seconds: 1), (timer) async {
        await _getScanStatus();
      });
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    return super.close();
  }
}
