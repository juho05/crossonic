part of 'connect_cubit.dart';

class ConnectState extends Equatable {
  final List<Device> devices;
  final Device? controllingDevice;

  const ConnectState({
    required this.devices,
    required this.controllingDevice,
  });

  @override
  List<Object?> get props => [devices, controllingDevice];
}
