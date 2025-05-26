import 'dart:convert';
import 'dart:math';
import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crypto/crypto.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthState extends SubsonicAuth {
  String get username;

  static const String storageKey = "auth_state";

  Future<void> persist(FlutterSecureStorage storage);

  static Future<AuthState?> load(FlutterSecureStorage storage) async {
    final data = await storage.read(key: "auth_state");
    if (data == null) {
      return null;
    }

    final json = (jsonDecode(data) as Map<String, Object?>);
    final type = json["type"] as String;
    return switch (type) {
      AuthStatePassword.type => AuthStatePassword.fromJson(json),
      AuthStateToken.type => AuthStateToken.fromJson(json),
      AuthStateApiKey.type => AuthStateApiKey.fromJson(json),
      _ => null,
    };
  }

  static Future<void> clear(FlutterSecureStorage storage) {
    return storage.delete(key: storageKey);
  }
}

class AuthStatePassword extends AuthState {
  @override
  final String username;
  final String password;

  static const String type = "password";

  AuthStatePassword({
    required this.username,
    required this.password,
  });

  factory AuthStatePassword.fromJson(Map<String, Object?> json) {
    return AuthStatePassword(
      username: json["username"] as String,
      password: json["password"] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "type": type,
      "username": username,
      "password": password,
    };
  }

  @override
  Future<void> persist(FlutterSecureStorage storage) {
    return storage.write(
        key: AuthState.storageKey, value: jsonEncode(toJson()));
  }

  @override
  Map<String, String> get queryParams => {
        "u": username,
        "p": password,
      };
}

class AuthStateToken extends AuthState {
  @override
  final String username;
  final String password;

  static const String type = "token";

  AuthStateToken({
    required this.username,
    required this.password,
  });

  factory AuthStateToken.fromJson(Map<String, Object?> json) {
    return AuthStateToken(
      username: json["username"] as String,
      password: json["password"] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "type": type,
      "username": username,
      "password": password,
    };
  }

  @override
  Future<void> persist(FlutterSecureStorage storage) {
    return storage.write(
        key: AuthState.storageKey, value: jsonEncode(toJson()));
  }

  @override
  Map<String, String> get queryParams {
    const letters =
        "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    final buffer = StringBuffer();
    for (var i = 0; i < 10; i++) {
      buffer.write(letters[Random.secure().nextInt(letters.length)]);
    }
    final salt = buffer.toString();
    final hash = md5.convert(utf8.encode(password + salt)).toString();
    return {
      "u": username,
      "t": hash,
      "s": salt,
    };
  }

  @override
  Map<String, String> get queryParamsCacheFriendly {
    final salt = "constantsalt";
    final hash = md5.convert(utf8.encode(password + salt)).toString();
    return {
      "u": username,
      "t": hash,
      "s": salt,
    };
  }
}

class AuthStateApiKey extends AuthState {
  @override
  final String username;
  final String apiKey;

  static const String type = "api_key";

  AuthStateApiKey({
    required this.username,
    required this.apiKey,
  });

  factory AuthStateApiKey.fromJson(Map<String, Object?> json) {
    return AuthStateApiKey(
      username: json["username"] as String,
      apiKey: json["key"] as String,
    );
  }

  Map<String, Object?> toJson() {
    return {
      "type": type,
      "username": username,
      "key": apiKey,
    };
  }

  @override
  Future<void> persist(FlutterSecureStorage storage) {
    return storage.write(
        key: AuthState.storageKey, value: jsonEncode(toJson()));
  }

  @override
  Map<String, String> get queryParams => {
        "apiKey": apiKey,
      };
}
