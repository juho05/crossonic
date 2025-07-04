import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';

/// macOS implementation of FlutterSecureStorage
class FlutterSecureStorageMacOS extends FlutterSecureStoragePlatform {
  static const _service = "org.crossonic.app";
  static const _label = "Crossonic";
  static const execPath = "/usr/bin/security";

  /// Registrar for FlutterSecureStorageMacOS
  static void registerWith() {
    FlutterSecureStoragePlatform.instance = FlutterSecureStorageMacOS();
  }

  /// Returns true if the storage contains the given [key].
  @override
  Future<bool> containsKey({
    required String key,
    required Map<String, String> options,
  }) async {
    key = _encode(key);
    var result = await Process.run(
      execPath,
      [
        "find-generic-password",
        "-s",
        _service,
        "-wa",
        key,
      ],
      stderrEncoding: const Utf8Codec(),
      stdoutEncoding: const Utf8Codec(),
    );
    if (result.exitCode != 0) {
      if (((result.stdout as String) + (result.stderr as String))
          .contains("could not be found")) {
        return false;
      }
    }
    return true;
  }

  /// Deletes associated value for the given [key].
  ///
  /// If the given [key] does not exist, nothing will happen.
  @override
  Future<void> delete({
    required String key,
    required Map<String, String> options,
  }) async {
    key = _encode(key);
    var result = await Process.run(
      execPath,
      [
        "delete-generic-password",
        "-s",
        _service,
        "-a",
        key,
      ],
      stderrEncoding: const Utf8Codec(),
      stdoutEncoding: const Utf8Codec(),
    );
    if (result.exitCode != 0) {
      if (((result.stdout as String) + (result.stderr as String))
          .contains("could not be found")) {
        return;
      }
      throw Exception(
          "$execPath exited with status code ${result.exitCode}:\n${result.stderr}");
    }
  }

  /// Deletes all keys with associated values.
  @override
  Future<void> deleteAll({
    required Map<String, String> options,
  }) async {
    throw UnimplementedError("deleteAll() not implemented");
  }

  /// Encrypts and saves the [key] with the given [value].
  ///
  /// If the key was already in the storage, its associated value is changed.
  /// If the value is null, deletes associated value for the given [key].
  @override
  Future<String?> read({
    required String key,
    required Map<String, String> options,
  }) async {
    key = _encode(key);
    var result = await Process.run(
      execPath,
      [
        "find-generic-password",
        "-s",
        _service,
        "-wa",
        key,
      ],
      stderrEncoding: const Utf8Codec(),
      stdoutEncoding: const Utf8Codec(),
    );
    if (result.exitCode != 0) {
      if (((result.stdout as String) + (result.stderr as String))
          .contains("could not be found")) {
        return null;
      }
      throw Exception(
          "$execPath exited with status code ${result.exitCode}:\n${result.stderr}");
    }
    return _decode((result.stdout as String).trim());
  }

  /// Decrypts and returns all keys with associated values.
  @override
  Future<Map<String, String>> readAll({
    required Map<String, String> options,
  }) async {
    throw UnimplementedError("readAll() not implemented");
  }

  /// Encrypts and saves the [key] with the given [value].
  ///
  /// If the key was already in the storage, its associated value is changed.
  /// If the value is null, deletes associated value for the given [key].
  @override
  Future<void> write({
    required String key,
    required String value,
    required Map<String, String> options,
  }) async {
    (key, value) = _encodeKeyValue(key, value);
    var result = await Process.run(
      execPath,
      [
        "add-generic-password",
        "-s",
        _service,
        "-l",
        _label,
        "-a",
        key,
        "-w",
        value,
        "-U"
      ],
      stderrEncoding: const Utf8Codec(),
    );
    if (result.exitCode != 0) {
      throw Exception(
          "$execPath exited with status code ${result.exitCode}:\n${result.stderr}");
    }
  }

  (String, String) _encodeKeyValue(String key, String value) {
    return (_encode(key), _encode(value));
  }

  String _encode(String str) {
    return base64.encode(utf8.encode(str));
  }

  String _decode(String str) {
    return utf8.decode(base64.decode(str));
  }
}
