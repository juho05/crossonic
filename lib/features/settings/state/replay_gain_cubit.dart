import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:equatable/equatable.dart';

part 'replay_gain_state.dart';

class ReplayGainCubit extends Cubit<ReplayGainState> {
  final Settings _settings;
  ReplayGainCubit(Settings settings)
      : _settings = settings,
        super(ReplayGainState(
          mode: settings.replayGain.value.mode,
          fallbackGain: settings.replayGain.value.fallbackGain.toString(),
          preferServerFallback: settings.replayGain.value.preferServerFallback,
        )) {
    _settings.replayGain.listen((replayGain) {
      emit(state.copyWith(
        mode: replayGain.mode,
        fallbackGain: replayGain.fallbackGain.toString(),
        preferServerFallback: replayGain.preferServerFallback,
      ));
    });
  }

  void modeChanged(ReplayGainMode mode) {
    _settings.setReplayGainMode(mode);
  }

  void fallbackGainChanged(String fallbackGain) {
    var gain = double.tryParse(fallbackGain);
    if (gain == null) {
      emit(state.copyWith(
          fallbackGain: fallbackGain,
          fallbackError: "Fallback gain must be a valid number"));
      return;
    }
    if (gain > 0) {
      gain = -gain;
    }
    emit(state.copyWith(fallbackError: ""));
    _settings.setReplayGainFallbackGain(gain);
  }

  void preferServerFallbackChanged(bool preferServer) {
    _settings.setReplayGainPreferServerFallback(preferServer);
  }
}
