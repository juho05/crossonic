import 'package:json_annotation/json_annotation.dart';

part 'disc_title_model.g.dart';

@JsonSerializable()
class DiscTitle {
  final int disc;
  final String title;

  DiscTitle({
    required this.disc,
    required this.title,
  });

  factory DiscTitle.fromJson(Map<String, dynamic> json) =>
      _$DiscTitleFromJson(json);
}
