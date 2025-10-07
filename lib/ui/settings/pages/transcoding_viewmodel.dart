import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:flutter/material.dart';

class TranscodingViewModel extends ChangeNotifier {
  final SettingsRepository _settings;

  bool get supportsMobile => _settings.transcoding.supportsMobile;
  Iterable<TranscodingCodec> get availableCodecs =>
      _settings.transcoding.availableCodecs;

  TranscodingCodec _codec;
  TranscodingCodec get codec => _codec;
  TranscodingCodec _codecMobile;
  TranscodingCodec get codecMobile => _codecMobile;

  int? _maxBitRate;
  int? get maxBitRate => _maxBitRate;
  int? _maxBitRateMobile;
  int? get maxBitRateMobile => _maxBitRateMobile;

  TranscodingViewModel({required SettingsRepository settings})
      : _settings = settings,
        _codec = settings.transcoding.codec,
        _codecMobile = settings.transcoding.codecMobile,
        _maxBitRate = settings.transcoding.maxBitRate,
        _maxBitRateMobile = settings.transcoding.maxBitRateMobile {
    _settings.transcoding.addListener(_onTranscodingChanged);
    _onTranscodingChanged();
  }

  void _onTranscodingChanged() {
    _codec = _settings.transcoding.codec;
    _codecMobile = _settings.transcoding.codecMobile;
    _maxBitRate = _settings.transcoding.maxBitRate;
    _maxBitRateMobile = _settings.transcoding.maxBitRateMobile;
    notifyListeners();
  }

  void reset() {
    _settings.transcoding.reset();
  }

  void updateCodec(TranscodingCodec codec) {
    _settings.transcoding.codec = codec;
    _settings.transcoding.resetMaxBitRate();
  }

  void updateCodecMobile(TranscodingCodec codec) {
    _settings.transcoding.codecMobile = codec;
    _settings.transcoding.resetMaxBitRateMobile();
  }

  void updateBitRate(int bitRate) {
    _settings.transcoding.maxBitRate = bitRate;
  }

  void updateBitRateMobile(int bitRate) {
    _settings.transcoding.maxBitRateMobile = bitRate;
  }

  @override
  void dispose() {
    _settings.transcoding.removeListener(_onTranscodingChanged);
    super.dispose();
  }
}
