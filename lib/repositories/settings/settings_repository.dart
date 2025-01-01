import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crossonic/repositories/api/api.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranscodeSetting extends Equatable {
  final String? format;
  final int? maxBitRate;

  const TranscodeSetting({required this.format, required this.maxBitRate});

  @override
  List<Object?> get props => [format, maxBitRate];
}

enum ReplayGainMode { disabled, track, album, auto }

class ReplayGainSetting extends Equatable {
  final ReplayGainMode mode;
  final double fallbackGain;
  final bool preferServerFallback;
  const ReplayGainSetting(
      {required this.mode,
      required this.fallbackGain,
      required this.preferServerFallback});

  @override
  List<Object?> get props => [mode, fallbackGain, preferServerFallback];

  ReplayGainSetting copyWith({
    ReplayGainMode? mode,
    double? fallbackGain,
    bool? preferServerFallback,
  }) {
    return ReplayGainSetting(
      mode: mode ?? this.mode,
      fallbackGain: fallbackGain ?? this.fallbackGain,
      preferServerFallback: preferServerFallback ?? this.preferServerFallback,
    );
  }
}

class Settings {
  final Connectivity _connectivity = Connectivity();
  final SharedPreferences _sharedPreferences;
  final APIRepository _apiRepository;

  TranscodeSetting _wifiTranscodeSetting =
      const TranscodeSetting(format: null, maxBitRate: null);
  TranscodeSetting get wifiTranscodeSetting => _wifiTranscodeSetting;
  set wifiTranscodeSetting(TranscodeSetting setting) {
    if (setting.format == null) {
      _sharedPreferences.remove("settings.transcode.wifi.format");
    } else {
      _sharedPreferences.setString(
          "settings.transcode.wifi.format", setting.format!);
    }
    if (setting.maxBitRate == null) {
      _sharedPreferences.remove("settings.transcode.wifi.bitrate");
    } else {
      _sharedPreferences.setInt(
          "settings.transcode.wifi.bitrate", setting.maxBitRate!);
    }
    _wifiTranscodeSetting = setting;
    getTranscodeSettings().then((value) => transcodeSetting.add(value));
  }

  TranscodeSetting _mobileTranscodeSetting =
      const TranscodeSetting(format: null, maxBitRate: null);
  TranscodeSetting get mobileTranscodeSetting => _mobileTranscodeSetting;
  set mobileTranscodeSetting(TranscodeSetting setting) {
    if (setting.format == null) {
      _sharedPreferences.remove("settings.transcode.mobile.format");
    } else {
      _sharedPreferences.setString(
          "settings.transcode.mobile.format", setting.format!);
    }
    if (setting.maxBitRate == null) {
      _sharedPreferences.remove("settings.transcode.mobile.bitrate");
    } else {
      _sharedPreferences.setInt(
          "settings.transcode.mobile.bitrate", setting.maxBitRate!);
    }
    _mobileTranscodeSetting = setting;
    getTranscodeSettings().then((value) => transcodeSetting.add(value));
  }

  Settings(
      {required SharedPreferences sharedPreferences,
      required APIRepository apiRepository})
      : _sharedPreferences = sharedPreferences,
        _apiRepository = apiRepository {
    _apiRepository.authStatus.listen((status) {
      if (status != AuthStatus.authenticated) {
        resetAll();
      }
    });
    _loadSettings().then((_) {
      _connectivity.onConnectivityChanged.listen((connections) async {
        transcodeSetting.add(await getTranscodeSettings(connections));
      });
    });
  }

  final BehaviorSubject<TranscodeSetting> transcodeSetting =
      BehaviorSubject.seeded(
          const TranscodeSetting(format: null, maxBitRate: null));

  Future<TranscodeSetting> getTranscodeSettings(
      [List<ConnectivityResult>? connections]) async {
    connections ??= await _connectivity.checkConnectivity();
    final isMobile = !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) &&
        connections.contains(ConnectivityResult.mobile) &&
        !connections.contains(ConnectivityResult.wifi) &&
        !connections.contains(ConnectivityResult.ethernet);
    return isMobile ? _mobileTranscodeSetting : _wifiTranscodeSetting;
  }

  Future<void> _loadTranscodeSettings() async {
    final wifiFormat =
        _sharedPreferences.getString("settings.transcode.wifi.format");
    final wifiBitRate =
        _sharedPreferences.getInt("settings.transcode.wifi.bitrate");
    _wifiTranscodeSetting = TranscodeSetting(
      format: wifiFormat,
      maxBitRate: wifiBitRate,
    );

    final mobileFormat =
        _sharedPreferences.getString("settings.transcode.mobile.format");
    final mobileBitRate =
        _sharedPreferences.getInt("settings.transcode.mobile.bitrate");
    _mobileTranscodeSetting = TranscodeSetting(
      format: mobileFormat,
      maxBitRate: mobileBitRate,
    );
    transcodeSetting.add(await getTranscodeSettings());
  }

  BehaviorSubject<ReplayGainSetting> replayGain =
      BehaviorSubject.seeded(const ReplayGainSetting(
    mode: ReplayGainMode.disabled,
    fallbackGain: -6,
    preferServerFallback: true,
  ));

  void setReplayGainMode(ReplayGainMode mode) {
    replayGain.add(replayGain.value.copyWith(mode: mode));
    _sharedPreferences.setString("settings.replaygain.mode", mode.name);
  }

  void setReplayGainFallbackGain(double fallbackGain) {
    replayGain.add(replayGain.value.copyWith(fallbackGain: fallbackGain));
    _sharedPreferences.setDouble(
        "settings.replaygain.fallbackGain", fallbackGain);
  }

  void setReplayGainPreferServerFallback(bool preferServerFallback) {
    replayGain.add(
        replayGain.value.copyWith(preferServerFallback: preferServerFallback));
    _sharedPreferences.setBool(
        "settings.replaygain.preferServerFallback", preferServerFallback);
  }

  void _loadReplayGain() {
    final modeStr = _sharedPreferences.getString("settings.replaygain.mode");
    if (modeStr == null) {
      replayGain.add(const ReplayGainSetting(
          mode: ReplayGainMode.disabled,
          fallbackGain: -6,
          preferServerFallback: true));
      return;
    }
    final fallbackGain =
        _sharedPreferences.getDouble("settings.replaygain.fallbackGain");
    final preferServerFallback =
        _sharedPreferences.getBool("settings.replaygain.preferServerFallback");
    replayGain.add(ReplayGainSetting(
      mode: ReplayGainMode.values.firstWhere((m) => m.name == modeStr),
      fallbackGain: fallbackGain ?? -6,
      preferServerFallback: preferServerFallback ?? true,
    ));
  }

  Future<void> _loadSettings() async {
    await _loadTranscodeSettings();
    _loadReplayGain();
  }

  Future<void> resetAll() async {
    final keys = _sharedPreferences.getKeys();
    var count = 0;
    for (var k in keys) {
      if (k.startsWith("settings.")) {
        _sharedPreferences.remove(k);
        count++;
      }
    }
    if (count > 0) await _loadSettings();
  }
}
