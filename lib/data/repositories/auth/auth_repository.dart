import 'dart:io';

import 'package:crossonic/data/repositories/auth/auth_state.dart';
import 'package:crossonic/data/repositories/auth/encrypted_storage.dart';
import 'package:crossonic/data/repositories/auth/encrypted_storage_linux.dart';
import 'package:crossonic/data/repositories/auth/encrypted_storage_secure_storage.dart';
import 'package:crossonic/data/repositories/auth/exceptions.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/version/version.dart';
import 'package:crossonic/data/services/database/database.dart';
import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crossonic/data/services/opensubsonic/exceptions.dart';
import 'package:crossonic/data/services/opensubsonic/models/opensubsonic_extension_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/server_info.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/exceptions.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class AuthRepository extends ChangeNotifier {
  final SubsonicService _openSubsonicService;
  final KeyValueRepository _keyValue;
  final Database _database;
  final EncryptedStorage _storage;

  Uri? _serverUri;
  AuthState? _state;
  ServerFeatures _serverFeatures = ServerFeatures();
  ServerFeatures get serverFeatures => _serverFeatures;

  Connection get con {
    if (!isAuthenticated) throw UnauthenticatedException();
    return Connection(
      baseUri: _serverUri!,
      auth: _state!,
      supportsPost: _serverFeatures.formPost.contains(1),
    );
  }

  Uri? get serverUri => _serverUri;

  AuthRepository({
    required SubsonicService openSubsonicService,
    required KeyValueRepository keyValueRepository,
    required Database database,
  })  : _keyValue = keyValueRepository,
        _database = database,
        _openSubsonicService = openSubsonicService,
        _storage = kIsWeb || !Platform.isLinux
            ? EncryptedStorageSecureStorage()
            : EncryptedStorageLinux(keyValueRepo: keyValueRepository);

  static const _serverUriKey = "server_uri";
  static const _serverFeaturesKey = "server_features";

  Future<void> loadState() async {
    final uri = await _keyValue.loadString(_serverUriKey);
    final serverFeatures =
        await _keyValue.loadObject(_serverFeaturesKey, ServerFeatures.fromJson);
    if (uri == null || serverFeatures == null) {
      await logout(false);
      return;
    }
    _serverUri = Uri.parse(uri);
    _serverFeatures = serverFeatures;
    _state = await AuthState.load(_storage);

    notifyListeners();

    _refreshServerFeatures();
  }

  Future<Result<void>> connect(Uri serverUri) async {
    if (_serverUri != null && _serverUri != serverUri) {
      await logout(false);
    }

    final result = await _openSubsonicService.fetchServerInfo(serverUri);
    switch (result) {
      case Err<ServerInfo>():
        if (result.error is UnexpectedResponseException) {
          return Result.error(InvalidServerException(
              (result.error as UnexpectedResponseException).message));
        }
        return Result.error(result.error);
      case Ok<ServerInfo>():
    }
    final info = result.value;

    final passwordPingRes = await _openSubsonicService.ping(Connection(
      baseUri: serverUri,
      auth: AuthStatePassword(username: "x", password: "x"),
      supportsPost: false,
    ));

    bool supportsPasswordAuth = true;
    switch (passwordPingRes) {
      case Err():
        if (passwordPingRes.error is SubsonicException) {
          final err = passwordPingRes.error as SubsonicException;
          supportsPasswordAuth =
              err.code != SubsonicErrorCode.authMechanismNotSupported;
        }
      case Ok():
    }

    final tokenPingRes = await _openSubsonicService.ping(Connection(
      baseUri: serverUri,
      auth: AuthStateToken(username: "x", password: "x"),
      supportsPost: false,
    ));

    bool supportsTokenAuth = true;
    switch (tokenPingRes) {
      case Err():
        if (tokenPingRes.error is SubsonicException) {
          final err = tokenPingRes.error as SubsonicException;
          supportsTokenAuth =
              err.code != SubsonicErrorCode.tokenAuthNotSupported &&
                  err.code != SubsonicErrorCode.authMechanismNotSupported;
        }
      case Ok():
    }

    Version? crossonicVersion;
    if (info.crossonicVersion != null) {
      try {
        crossonicVersion = Version.parse(info.crossonicVersion!);
      } catch (_) {
        Log.error(
            "Failed to parse crossonic version: ${info.crossonicVersion}");
      }
    }

    _serverFeatures = ServerFeatures(
      isOpenSubsonic: info.isOpenSubsonic,
      isCrossonic: info.isCrossonic,
      isNavidrome: info.isNavidrome,
      supportsPasswordAuth: supportsPasswordAuth,
      supportsTokenAuth: supportsTokenAuth,
      crossonicVersion: crossonicVersion,
    );
    _serverUri = serverUri;

    // calls persistState and notifyListeners
    await _loadOpenSubsonicExtensions();

    return const Result.ok(null);
  }

  Future<Result<void>> _refreshServerFeatures() async {
    final result = await _openSubsonicService.fetchServerInfo(_serverUri!);
    switch (result) {
      case Err<ServerInfo>():
        if (result.error is UnexpectedResponseException) {
          return Result.error(InvalidServerException(
              (result.error as UnexpectedResponseException).message));
        }
        return Result.error(result.error);
      case Ok<ServerInfo>():
    }
    final info = result.value;

    Version? crossonicVersion;
    if (info.crossonicVersion != null) {
      try {
        crossonicVersion = Version.parse(info.crossonicVersion!);
      } catch (_) {
        Log.error(
            "Failed to parse crossonic version: ${info.crossonicVersion}");
      }
    }

    _serverFeatures = _serverFeatures.copyWith(
      isOpenSubsonic: info.isOpenSubsonic,
      isCrossonic: info.isCrossonic,
      isNavidrome: info.isNavidrome,
      crossonicVersion: crossonicVersion,
    );

    // calls persistState and notifyListeners
    await _loadOpenSubsonicExtensions();

    return const Result.ok(null);
  }

  Future<Result<void>> loginUsernamePassword(
      String username, String password, bool useTokenAuth) async {
    final auth = useTokenAuth
        ? AuthStateToken(username: username, password: password)
        : AuthStatePassword(username: username, password: password);
    final connection = Connection(
      baseUri: _serverUri!,
      auth: auth,
      supportsPost: _serverFeatures.formPost.contains(1),
    );

    final result = await _openSubsonicService.ping(connection);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }

    _state = auth;

    await _persistState();

    notifyListeners();

    if (!serverFeatures.loadedExtensions) {
      _loadOpenSubsonicExtensions();
    }

    return const Result.ok(null);
  }

  Future<Result<void>> loginApiKey(String apiKey) async {
    final connection = Connection(
      baseUri: _serverUri!,
      auth: AuthStateApiKey(username: "", apiKey: apiKey),
      supportsPost: _serverFeatures.formPost.contains(1),
    );
    final result = await _openSubsonicService.tokenInfo(connection);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }

    _state = AuthStateApiKey(username: result.value.username, apiKey: apiKey);

    await _persistState();

    notifyListeners();

    return const Result.ok(null);
  }

  Future<void> logout(bool keepServerUri) async {
    await _database.clearAll();
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
      result = await _openSubsonicService.getOpenSubsonicExtensions(Connection(
        baseUri: _serverUri!,
        auth: EmptyAuth(),
        supportsPost: false,
      ));
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
        crossonicVersion: _serverFeatures.crossonicVersion,
      );
    } else {
      Log.error(
          "failed to load OpenSubsonic extensions", (result as Err).error);
    }
    await _persistState();
    notifyListeners();
  }

  Future<void> _persistState() async {
    if (_serverUri != null) {
      await _keyValue.store(_serverFeaturesKey, _serverFeatures);
      await _keyValue.store(_serverUriKey, _serverUri.toString());
    } else {
      await _keyValue.remove(_serverUriKey);
      await _keyValue.remove(_serverFeaturesKey);
    }
    if (_state != null) {
      await _state!.persist(_storage);
    } else {
      await AuthState.clear(_storage);
    }
  }

  bool get hasServer => _serverUri != null;
  bool get isAuthenticated => hasServer && _state != null;
}
