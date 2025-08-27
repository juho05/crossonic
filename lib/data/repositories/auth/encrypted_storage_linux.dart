import 'dart:convert';

import 'package:crossonic/data/repositories/auth/encrypted_storage.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:dbus_secrets/dbus_secrets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStorageLinux implements EncryptedStorage {
  // login secrets will be encrypted with this key if dbus secret service does not work
  static final SecretKey _fallbackKey = SecretKey(Uint8List.fromList([
    0x6b,
    0xb9,
    0x73,
    0xbd,
    0x07,
    0x33,
    0xc5,
    0xb1,
    0x91,
    0x3b,
    0xdc,
    0x5c,
    0x68,
    0x9f,
    0xab,
    0x6b,
  ]));
  static const String _keyValuePrefix = "encrypted_storage";

  final KeyValueRepository _keyValue;

  bool _initialized = false;
  bool _useFallback = false;

  DBusSecrets? _storage;
  final AesGcm _fallbackEncryption;

  EncryptedStorageLinux({
    required KeyValueRepository keyValueRepo,
  })  : _keyValue = keyValueRepo,
        _fallbackEncryption = AesGcm.with128bits();

  @override
  Future<String?> read(String key) async {
    await _ensureInitialized();

    if (_useFallback) {
      return _readFallback(key);
    }

    return await _storage!.get(key);
  }

  @override
  Future<void> delete(String key) async {
    await _ensureInitialized();

    if (_useFallback) {
      return _deleteFallback(key);
    }

    await _storage!.delete(key);
  }

  @override
  Future<void> write(String key, String value) async {
    await _ensureInitialized();

    if (_useFallback) {
      return _writeFallback(key, value);
    }

    await _storage!.set(key, value);
  }

  Future<String?> _readFallback(String key) async {
    final value = await _keyValue.loadString("$_keyValuePrefix.$key");
    if (value == null) return null;
    return await _decryptValue(value);
  }

  Future<void> _deleteFallback(String key) async {
    await _keyValue.remove("$_keyValuePrefix.$key");
  }

  Future<void> _writeFallback(String key, String value) async {
    final encrypted = await _encryptValue(value);
    await _keyValue.store("$_keyValuePrefix.$key", encrypted);
  }

  Future<String> _encryptValue(String value) async {
    final nonce = _fallbackEncryption.newNonce();
    final secretBox = await _fallbackEncryption.encrypt(value.codeUnits,
        secretKey: _fallbackKey, nonce: nonce);

    final bytes = secretBox.concatenation();

    return "${secretBox.nonce.length}.${secretBox.mac.bytes.length}.${base64.encode(bytes)}";
  }

  Future<String> _decryptValue(String value) async {
    final parts = value.split(".");
    assert(parts.length == 3);
    final bytes = base64.decode(parts[2]);
    final secretBox = SecretBox.fromConcatenation(bytes,
        nonceLength: int.parse(parts[0]), macLength: int.parse(parts[1]));
    return await _fallbackEncryption.decryptString(secretBox,
        secretKey: _fallbackKey);
  }

  bool _migrationDone = false;
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    try {
      _storage = DBusSecrets(appName: "org.crossonic.app");
      if (!await _storage!.initialize()) {
        _useFallback = true;
        Log.error(
            "Failed to initialize dbus secret storage, falling back to insecure storage in database");
      }
      if (!await _storage!.unlock()) {
        _useFallback = true;
        Log.error(
            "Failed to unlock dbus secret storage, falling back to insecure storage in database");
      }
    } catch (e) {
      Log.error(
          "Failed to initialize dbus secret storage, falling back to insecure storage in database",
          e: e);
      _useFallback = true;
    }

    await _migrate();
  }

  // migration from flutter_secure_storage or fallback to dbus_secrets
  Future<void> _migrate() async {
    if (_migrationDone) return;
    _migrationDone = true;

    if (!_useFallback) {
      final keys = await _keyValue.keys();
      for (final k in keys) {
        if (k.startsWith("$_keyValuePrefix.")) {
          final key = k.substring(_keyValuePrefix.length + 1);
          final value = await _keyValue.loadString(k);
          Log.debug(
              "Migrating $key from fallback encrypted database storage to dbus secret service");
          await write(key, await _decryptValue(value!));
          await _keyValue.remove(k);
        }
      }
    }

    try {
      final storage = const FlutterSecureStorage();
      final oldData = await storage.readAll();
      for (final kv in oldData.entries) {
        await write(kv.key, kv.value);
        Log.debug(
            "Migrating ${kv.key} from flutter_secure_storage to new encrypted storage");
      }
      await storage.deleteAll();
    } catch (e) {
      Log.error(
        "Failed to migrate from flutter_secure_storage to dbus_secrets",
        e: e,
      );
    }
  }
}
