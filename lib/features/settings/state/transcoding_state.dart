part of 'transcoding_cubit.dart';

class TranscodingState extends Equatable {
  final String? wifiFormat;
  final String? mobileFormat;
  final int? wifiBitRate;
  final int? mobileBitRate;

  const TranscodingState({
    required this.wifiFormat,
    required this.mobileFormat,
    required this.wifiBitRate,
    required this.mobileBitRate,
  });

  @override
  List<Object?> get props =>
      [wifiFormat, mobileFormat, wifiBitRate, mobileBitRate];
}
