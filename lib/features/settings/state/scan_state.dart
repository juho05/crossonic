part of 'scan_cubit.dart';

class ScanState extends Equatable {
  final bool loadingStatus;
  final int? scannedCount;
  final bool scanning;
  const ScanState({
    this.loadingStatus = false,
    required this.scannedCount,
    required this.scanning,
  });

  @override
  List<Object?> get props => [scannedCount, scanning];
}
