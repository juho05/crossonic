import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'speaker_state.g.dart';

@JsonSerializable()
class SpeakerState extends Equatable {
  final String state;
  final int positionMs;

  const SpeakerState({required this.state, required this.positionMs});

  factory SpeakerState.fromJson(Map<String, dynamic> json) =>
      _$SpeakerStateFromJson(json);

  @override
  List<Object> get props => [state, positionMs];
}
