import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/services/connect/connect_manager.dart';
import 'package:crossonic/services/connect/models/device.dart';
import 'package:equatable/equatable.dart';

part 'connect_state.dart';

class ConnectCubit extends Cubit<ConnectState> {
  late final StreamSubscription _devicesSubscription;
  late final StreamSubscription _controllingDeviceSubscription;
  ConnectCubit(ConnectManager manager)
      : super(const ConnectState(devices: [], controllingDevice: null)) {
    _devicesSubscription = manager.connectedDevices.listen((devices) {
      emit(ConnectState(
          devices: devices,
          controllingDevice: manager.controllingDevice.value));
    });
    _controllingDeviceSubscription = manager.controllingDevice.listen((device) {
      emit(ConnectState(
          devices: manager.connectedDevices.value, controllingDevice: device));
    });
  }

  @override
  Future<void> close() async {
    await _devicesSubscription.cancel();
    await _controllingDeviceSubscription.cancel();
    return super.close();
  }
}
