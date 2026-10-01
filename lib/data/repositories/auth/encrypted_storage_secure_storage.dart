/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:convert';
import 'dart:io';

import 'package:crossonic/data/repositories/auth/encrypted_storage.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStorageSecureStorage implements EncryptedStorage {
  final FlutterSecureStorage _storage;

  EncryptedStorageSecureStorage()
    : _storage = const FlutterSecureStorage(
        mOptions: MacOsOptions(
          accountName: "org.crossonic.app",
          usesDataProtectionKeychain: false,
        ),
      );

  @override
  Future<String?> read(String key) async {
    final String? value;
    try {
      value = await _storage.read(key: key);
    } catch (e) {
      Log.warn("Failed to read keychain item", e: e);
      return null;
    }
    if (value != null || !Platform.isMacOS) return value;
    return _migrateLegacyMacOS(key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
    if (!Platform.isMacOS) return;
    try {
      await _LegacyMacOSKeychain.delete(key);
    } catch (e) {
      Log.warn("Failed to delete legacy keychain item", e: e);
      await _storage.write(key: _legacyDeletedKey(key), value: "1");
    }
  }

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
    if (Platform.isMacOS) await _storage.delete(key: _legacyDeletedKey(key));
  }

  static String _legacyDeletedKey(String key) => "$key.legacyDeleted";

  Future<String?> _migrateLegacyMacOS(String key) async {
    try {
      if (await _storage.containsKey(key: _legacyDeletedKey(key))) return null;
    } catch (e) {
      Log.warn("Failed to read keychain item", e: e);
      return null;
    }

    final String? value;
    try {
      value = await _LegacyMacOSKeychain.read(key);
    } catch (e) {
      Log.warn("Failed to read legacy keychain item", e: e);
      return null;
    }
    if (value == null) return null;

    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      Log.warn("Failed to migrate legacy keychain item", e: e);
      return value;
    }
    try {
      await _LegacyMacOSKeychain.delete(key);
    } catch (e) {
      Log.warn("Failed to delete migrated legacy keychain item", e: e);
    }
    Log.info("Migrated legacy keychain item to flutter_secure_storage");
    return value;
  }
}

class _LegacyMacOSKeychain {
  static const _service = "org.crossonic.app";
  static const _execPath = "/usr/bin/security";

  static Future<String?> read(String key) async {
    final result = await _run([
      "find-generic-password",
      "-s",
      _service,
      "-wa",
      _encode(key),
    ]);
    if (result == null) return null;
    return utf8.decode(base64.decode(result.trim()));
  }

  static Future<void> delete(String key) async {
    await _run(["delete-generic-password", "-s", _service, "-a", _encode(key)]);
  }

  static Future<String?> _run(List<String> args) async {
    final result = await Process.run(
      _execPath,
      args,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode == 0) return result.stdout as String;
    if ((result.stderr as String).contains("could not be found")) return null;
    throw Exception(
      "$_execPath exited with status code ${result.exitCode}:\n${result.stderr}",
    );
  }

  static String _encode(String str) => base64.encode(utf8.encode(str));
}
