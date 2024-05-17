import 'package:json_annotation/json_annotation.dart';

part 'replay_gain_model.g.dart';

@JsonSerializable()
class ReplayGain {
  final double? trackGain;
  final double? albumGain;
  final double? trackPeak;
  final double? albumPeak;
  final double? baseGain;
  final double? fallbackGain;

  ReplayGain({
    required this.trackGain,
    required this.albumGain,
    required this.trackPeak,
    required this.albumPeak,
    required this.baseGain,
    required this.fallbackGain,
  });

  factory ReplayGain.fromJson(Map<String, dynamic> json) =>
      _$ReplayGainFromJson(json);
}
