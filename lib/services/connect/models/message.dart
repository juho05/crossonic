import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part "message.g.dart";

@JsonSerializable()
class Message extends Equatable {
  final String op;
  final String type;
  final String source;
  final String target;
  final Map<String, dynamic>? payload;

  const Message({
    required this.op,
    required this.type,
    this.source = "",
    required this.target,
    this.payload,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  @override
  List<Object?> get props => [op, type, source, target, payload];
}
