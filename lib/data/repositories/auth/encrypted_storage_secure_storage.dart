/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/data/repositories/auth/encrypted_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptedStorageSecureStorage implements EncryptedStorage {
  final FlutterSecureStorage _storage;

  EncryptedStorageSecureStorage() : _storage = const FlutterSecureStorage();

  @override
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}
