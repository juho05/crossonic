import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:equatable/equatable.dart';

part 'transcoding_state.dart';

class TranscodingOption {
  final String? name;
  final String displayName;
  final int? minBitRate;
  final int? maxBitRate;
  const TranscodingOption(
      this.name, this.displayName, this.minBitRate, this.maxBitRate);
}

class TranscodingCubit extends Cubit<TranscodingState> {
  static const Map<String, TranscodingOption> options = {
    "default": TranscodingOption(null, "Default", null, null),
    "raw": TranscodingOption("raw", "Original", 0, 0),
    "mp3": TranscodingOption("mp3", "MP3", 64, 320),
    "opus": TranscodingOption("opus", "Opus", 32, 512),
    "vorbis": TranscodingOption("vorbis", "Vorbis", 64, 500),
    "aac": TranscodingOption("aac", "AAC", 64, 500),
  };

  final Settings _settings;

  TranscodingCubit(Settings settings)
      : _settings = settings,
        super(const TranscodingState(
            wifiFormat: null,
            mobileFormat: null,
            wifiBitRate: null,
            mobileBitRate: null)) {
    _update();
  }

  void _update() {
    final wifi = _settings.wifiTranscodeSetting;
    final mobile = _settings.mobileTranscodeSetting;
    emit(TranscodingState(
      wifiFormat: wifi.format,
      wifiBitRate: wifi.maxBitRate,
      mobileFormat: mobile.format,
      mobileBitRate: mobile.maxBitRate,
    ));
  }

  void setWifiFormat(String format) {
    _settings.wifiTranscodeSetting = TranscodeSetting(
      format: options[format]?.name,
      maxBitRate: null,
    );
    _update();
  }

  void setMobileFormat(String format) {
    _settings.mobileTranscodeSetting = TranscodeSetting(
      format: options[format]?.name,
      maxBitRate: null,
    );
    _update();
  }

  void setWifiBitRate(int? bitRate) {
    _settings.wifiTranscodeSetting = TranscodeSetting(
      format: _settings.wifiTranscodeSetting.format,
      maxBitRate: bitRate,
    );
    _update();
  }

  void setMobileBitRate(int? bitRate) {
    _settings.mobileTranscodeSetting = TranscodeSetting(
      format: _settings.mobileTranscodeSetting.format,
      maxBitRate: bitRate,
    );
    _update();
  }
}
