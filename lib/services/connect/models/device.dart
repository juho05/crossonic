import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device.g.dart';

@JsonSerializable()
class Device extends Equatable {
  final String name;
  final String id;
  final String platform;

  const Device({required this.name, required this.id, required this.platform});

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  @override
  List<Object> get props => [name, id, platform];
}
