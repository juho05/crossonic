import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:flutter/foundation.dart';

enum TranscodingCodec {
  serverDefault([128, 192, 256, 320]),
  raw([]),
  mp3([64, 128, 192, 256, 320]),
  opus([32, 64, 128, 192, 256, 320, 512]),
  vorbis([96, 128, 192, 256, 320, 480]);

  const TranscodingCodec(this.validBitRates);

  final List<int> validBitRates;
}

class TranscodingSettings extends ChangeNotifier {
  final KeyValueRepository _repo;
  final SubsonicRepository _subsonic;

  List<TranscodingCodec> _availableCodecs = [];
  Iterable<TranscodingCodec> get availableCodecs => _availableCodecs;

  bool _supportsMobile = false;
  bool get supportsMobile => _supportsMobile;

  static const String _codecKey = "transcoding.codec";
  TranscodingCodec get _codecDefault {
    if (kIsWeb) {
      return TranscodingCodec.raw;
    }
    if (_availableCodecs.contains(TranscodingCodec.opus)) {
      return TranscodingCodec.opus;
    }
    return TranscodingCodec.serverDefault;
  }

  TranscodingCodec _codec = TranscodingCodec.serverDefault;
  TranscodingCodec get codec => _codec;

  static const String _codecMobileKey = "transcoding.codec_mobile";
  TranscodingCodec get _codecMobileDefault {
    if (kIsWeb) {
      return TranscodingCodec.raw;
    }
    if (_availableCodecs.contains(TranscodingCodec.opus)) {
      return TranscodingCodec.opus;
    }
    return TranscodingCodec.serverDefault;
  }

  TranscodingCodec _codecMobile = TranscodingCodec.serverDefault;
  TranscodingCodec get codecMobile => _codecMobile;

  static const String _maxBitRateKey = "transcoding.max_bitrate";
  static const int? _maxBitRateDefault = null;
  int? _maxBitRate = _maxBitRateDefault;
  int? get maxBitRate => _maxBitRate;

  static const String _maxBitRateMobileKey = "transcoding.max_bitrate_mobile";
  static const int? _maxBitRateMobileDefault = null;
  int? _maxBitRateMobile = _maxBitRateMobileDefault;
  int? get maxBitRateMobile => _maxBitRateMobile;

  StreamSubscription? _connectivitySubscription;

  TranscodingSettings({
    required KeyValueRepository keyValueRepository,
    required SubsonicRepository subsonicRepository,
  })  : _repo = keyValueRepository,
        _subsonic = subsonicRepository;

  Future<(TranscodingCodec, int?)> activeTranscoding() async {
    final connectivity = await Connectivity().checkConnectivity();
    final isMobile = _supportsMobile &&
        !connectivity.contains(ConnectivityResult.wifi) &&
        !connectivity.contains(ConnectivityResult.ethernet);
    return (
      isMobile ? _codecMobile : _codec,
      isMobile ? _maxBitRateMobile : _maxBitRate
    );
  }

  Future<void> load() async {
    _availableCodecs = _subsonic.supports.transcodeCodecs;
    _supportsMobile =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

    if (_supportsMobile) {
      _connectivitySubscription = Connectivity()
          .onConnectivityChanged
          .listen((event) => notifyListeners());
    }
    _codec = TranscodingCodec.values
        .byName((await _repo.loadString(_codecKey)) ?? _codecDefault.name);
    _codecMobile = TranscodingCodec.values.byName(
        (await _repo.loadString(_codecMobileKey)) ?? _codecMobileDefault.name);

    _maxBitRate = await _repo.loadInt(_maxBitRateKey);
    _maxBitRateMobile = await _repo.loadInt(_maxBitRateMobileKey);
    notifyListeners();
  }

  void reset() {
    _codec = _codecDefault;
    _codecMobile = _codecMobileDefault;

    _maxBitRate = _maxBitRateDefault;
    _maxBitRateMobile = _maxBitRateMobileDefault;

    notifyListeners();

    _repo.remove(_codecKey);
    _repo.remove(_codecMobileKey);
    _repo.remove(_maxBitRateKey);
    _repo.remove(_maxBitRateMobileKey);
  }

  set codec(TranscodingCodec codec) {
    if (_codec == codec) return;
    _codec = codec;
    notifyListeners();
    _repo.store(_codecKey, _codec.name);
  }

  set codecMobile(TranscodingCodec codec) {
    if (_codecMobile == codec) return;
    _codecMobile = codec;
    notifyListeners();
    _repo.store(_codecMobileKey, _codecMobile.name);
  }

  set maxBitRate(int? bitRate) {
    if (_maxBitRate == bitRate) return;
    _maxBitRate = bitRate;
    notifyListeners();
    if (_maxBitRate != null) {
      _repo.store(_maxBitRateKey, _maxBitRate);
    } else {
      _repo.remove(_maxBitRateKey);
    }
  }

  set maxBitRateMobile(int? bitRate) {
    if (_maxBitRateMobile == bitRate) return;
    _maxBitRateMobile = bitRate;
    notifyListeners();
    if (_maxBitRateMobile != null) {
      _repo.store(_maxBitRateMobileKey, _maxBitRateMobile);
    } else {
      _repo.remove(_maxBitRateMobileKey);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
