import 'dart:convert';

import 'package:crossonic/data/repositories/auth/auth_state.dart';
import 'package:crossonic/data/repositories/auth/exceptions.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
import 'package:crossonic/data/services/opensubsonic/models/opensubsonic_extension_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/server_info.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferencesAsync _sharedPreferences;
  final SubsonicService _openSubsonicService;

  Uri? _serverUri;
  AuthState? _state;
  ServerFeatures _serverFeatures = ServerFeatures();
  ServerFeatures get serverFeatures => _serverFeatures;

  Connection get con {
    if (!isAuthenticated) throw UnauthenticatedException();
    return Connection(baseUri: _serverUri!, auth: _state!);
  }

  Uri? get serverUri => _serverUri;

  AuthRepository({
    required FlutterSecureStorage secureStorage,
    required SharedPreferencesAsync sharedPreferences,
    required SubsonicService openSubsonicService,
  })  : _secureStorage = secureStorage,
        _sharedPreferences = sharedPreferences,
        _openSubsonicService = openSubsonicService;

  static const _serverUriKey = "server_uri";
  static const _serverFeaturesKey = "server_features";

  Future<void> loadState() async {
    final uri = await _sharedPreferences.getString(_serverUriKey);
    final serverFeatures =
        await _sharedPreferences.getString(_serverFeaturesKey);
    if (uri == null || serverFeatures == null) {
      await logout(false);
      return;
    }
    _serverUri = Uri.parse(uri);
    _serverFeatures = ServerFeatures.fromJson(jsonDecode(serverFeatures));
    _state = await AuthState.load(_secureStorage);

    notifyListeners();

    // TODO refresh server features
  }

  Future<Result<void>> connect(Uri serverUri) async {
    if (_serverUri != null && _serverUri != serverUri) {
      await logout(false);
    }

    final result = await _openSubsonicService.fetchServerInfo(serverUri);
    switch (result) {
      case Error<ServerInfo>():
        if (result is UnexpectedResponseException) {
          return Result.error(InvalidServerException(
              (result.error as UnexpectedResponseException).message));
        }
        return Result.error(result.error);
      case Ok<ServerInfo>():
    }
    final info = result.value;

    final passwordPingRes = await _openSubsonicService.ping(Connection(
        baseUri: serverUri,
        auth: AuthStatePassword(username: "x", password: "x")));

    bool supportsPasswordAuth = true;
    switch (passwordPingRes) {
      case Error():
        if (passwordPingRes.error is SubsonicException) {
          final err = passwordPingRes.error as SubsonicException;
          supportsPasswordAuth =
              err.code != SubsonicErrorCode.authMechanismNotSupported;
        }
      case Ok():
    }

    final tokenPingRes = await _openSubsonicService.ping(Connection(
        baseUri: serverUri,
        auth: AuthStateToken(username: "x", password: "x")));

    bool supportsTokenAuth = true;
    switch (tokenPingRes) {
      case Error():
        if (tokenPingRes.error is SubsonicException) {
          final err = tokenPingRes.error as SubsonicException;
          supportsTokenAuth =
              err.code != SubsonicErrorCode.tokenAuthNotSupported &&
                  err.code != SubsonicErrorCode.authMechanismNotSupported;
        }
      case Ok():
    }

    _serverFeatures = ServerFeatures(
      isOpenSubsonic: info.isOpenSubsonic,
      isCrossonic: info.isCrossonic,
      supportsPasswordAuth: supportsPasswordAuth,
      supportsTokenAuth: supportsTokenAuth,
    );
    _serverUri = serverUri;

    // calls persistState and notifyListeners
    await _loadOpenSubsonicExtensions();

    return Result.ok(null);
  }

  Future<Result<void>> loginUsernamPassword(
      String username, String password, bool useTokenAuth) async {
    final auth = useTokenAuth
        ? AuthStateToken(username: username, password: password)
        : AuthStatePassword(username: username, password: password);
    final connection = Connection(
      baseUri: _serverUri!,
      auth: auth,
    );

    final result = await _openSubsonicService.ping(connection);
    switch (result) {
      case Error():
        return Result.error(result.error);
      case Ok():
    }

    _state = auth;

    await _persistState();

    notifyListeners();

    if (!serverFeatures.loadedExtensions) {
      _loadOpenSubsonicExtensions();
    }

    return Result.ok(null);
  }

  Future<Result<void>> loginApiKey(String apiKey) async {
    final connection = Connection(
        baseUri: _serverUri!,
        auth: AuthStateApiKey(username: "", apiKey: apiKey));
    final result = await _openSubsonicService.tokenInfo(connection);
    switch (result) {
      case Error():
        return Result.error(result.error);
      case Ok():
    }

    _state = AuthStateApiKey(username: result.value.username, apiKey: apiKey);

    await _persistState();

    notifyListeners();

    return Result.ok(null);
  }

  Future<void> logout(bool keepServerUri) async {
    _state = null;
    if (!keepServerUri) {
      _serverUri = null;
      _serverFeatures = ServerFeatures();
    }
    await _persistState();
    notifyListeners();
  }

  Future<void> _loadOpenSubsonicExtensions() async {
    final Result<Iterable<OpenSubsonicExtensionModel>> result;
    if (isAuthenticated) {
      result = await _openSubsonicService.getOpenSubsonicExtensions(con);
    } else {
      result = await _openSubsonicService.getOpenSubsonicExtensions(
          Connection(baseUri: _serverUri!, auth: EmptyAuth()));
    }
    if (result is Ok) {
      final extensions =
          (result as Ok<Iterable<OpenSubsonicExtensionModel>>).value;
      Set<int> formPost = <int>{};
      Set<int> transcodeOffset = <int>{};
      Set<int> songLyrics = <int>{};
      Set<int> apiKeyAuthentication = <int>{};
      for (var ext in extensions) {
        switch (ext.name) {
          case "formPost":
            formPost = ext.versions.toSet();
          case "transcodeOffset":
            transcodeOffset = ext.versions.toSet();
          case "songLyrics":
            songLyrics = ext.versions.toSet();
          case "apiKeyAuthentication":
            apiKeyAuthentication = ext.versions.toSet();
        }
      }
      _serverFeatures = _serverFeatures.copyWith(
        loadedExtensions: true,
        formPost: formPost,
        transcodeOffset: transcodeOffset,
        songLyrics: songLyrics,
        apiKeyAuthentication: apiKeyAuthentication,
      );
      await _persistState();
      notifyListeners();
    } else {
      print(
          "failed to load OpenSubsonic extensions: ${(result as Error).error}");
    }
  }

  Future<void> _persistState() async {
    if (_serverUri != null) {
      await _sharedPreferences.setString(
          _serverFeaturesKey, jsonEncode(_serverFeatures.toJson()));
      await _sharedPreferences.setString(_serverUriKey, _serverUri.toString());
    } else {
      await _sharedPreferences.remove(_serverUriKey);
      await _sharedPreferences.remove(_serverFeaturesKey);
    }
    if (_state != null) {
      await _state!.persist(_secureStorage);
    } else {
      await AuthState.clear(_secureStorage);
    }
  }

  bool get hasServer => _serverUri != null;
  bool get isAuthenticated => hasServer && _state != null;
}
