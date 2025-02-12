import 'package:json_annotation/json_annotation.dart';

part 'token_info_model.g.dart';

@JsonSerializable()
class TokenInfoModel {
  final String username;

  TokenInfoModel({required this.username});

  factory TokenInfoModel.fromJson(Map<String, dynamic> json) =>
      _$TokenInfoModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenInfoModelToJson(this);
}
