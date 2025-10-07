import 'package:json_annotation/json_annotation.dart';

part 'opensubsonic_extension_model.g.dart';

@JsonSerializable()
class OpenSubsonicExtensionModel {
  final String name;
  final List<int> versions;

  OpenSubsonicExtensionModel({required this.name, required this.versions});

  factory OpenSubsonicExtensionModel.fromJson(Map<String, dynamic> json) =>
      _$OpenSubsonicExtensionModelFromJson(json);

  Map<String, dynamic> toJson() => _$OpenSubsonicExtensionModelToJson(this);

  @override
  String toString() {
    return "$name: ${versions.join(", ")}";
  }
}
