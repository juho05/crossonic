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

  Future<void> _loadSettings() async {
    await _loadTranscodeSettings();
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
