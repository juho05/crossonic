part of 'replay_gain_cubit.dart';

class ReplayGainState extends Equatable {
  final ReplayGainMode mode;
  final String fallbackGain;
  final String fallbackError;
  final bool preferServerFallback;

  const ReplayGainState({
    required this.mode,
    required this.fallbackGain,
    this.fallbackError = "",
    required this.preferServerFallback,
  });

  ReplayGainState copyWith({
    ReplayGainMode? mode,
    String? fallbackGain,
    String? fallbackError,
    bool? preferServerFallback,
  }) =>
      ReplayGainState(
        mode: mode ?? this.mode,
        fallbackGain: fallbackGain ?? this.fallbackGain,
        fallbackError: fallbackError ?? this.fallbackError,
        preferServerFallback: preferServerFallback ?? this.preferServerFallback,
      );

  @override
  List<Object> get props =>
      [mode, fallbackGain, fallbackError, preferServerFallback];
}
