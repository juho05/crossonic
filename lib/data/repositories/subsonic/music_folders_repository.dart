/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/music_folder.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class MusicFoldersRepository extends ChangeNotifier {
  static const String _selectedKey = "music_folders.selected";
  static const Duration _debounceDuration = Duration(seconds: 1);

  final AuthRepository _auth;
  final SubsonicService _subsonic;
  final KeyValueRepository _keyValue;

  final Set<int> _selected = {};
  Set<int> get selected => UnmodifiableSetView(_selected);

  final StreamController<void> _debounced = StreamController.broadcast();
  Stream<void> get debounced => _debounced.stream;

  MusicFoldersRepository({
    required AuthRepository auth,
    required SubsonicService subsonic,
    required KeyValueRepository keyValue,
  }) : _auth = auth,
       _subsonic = subsonic,
       _keyValue = keyValue {
    auth.addListener(_onAuthChanged);
    addListener(_onChanged);
  }

  Timer? _changedDebounce;
  void _onChanged() {
    if (!_debounced.hasListener) return;
    _changedDebounce?.cancel();
    _changedDebounce = Timer(_debounceDuration, () => _debounced.add(null));
  }

  void _onAuthChanged() {
    if (!_auth.isAuthenticated) {
      _selected.clear();
      notifyListeners();
    }
  }

  Future<Result<List<MusicFolder>>> getMusicFolders() async {
    final result = await _subsonic.getMusicFolders(_auth.con);
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    final folders = result.value.musicFolder
        .map((f) => MusicFolder(id: f.id, name: f.name ?? "Unnamed folder"))
        .toList();

    _selected.removeWhere((id) => !folders.any((f) => f.id == id));

    return Result.ok(folders);
  }

  Future<void> load() async {
    final list = await _keyValue.loadIntList(_selectedKey);
    _selected.clear();
    _selected.addAll(list ?? []);
    notifyListeners();
  }

  Future<void> setSelected(Set<int> musicFolderId) async {
    _selected.clear();
    _selected.addAll(musicFolderId);
    notifyListeners();
    await _store();
  }

  Future<void> select(int musicFolderId) async {
    if (_selected.contains(musicFolderId)) return;
    _selected.add(musicFolderId);
    notifyListeners();
    await _store();
  }

  Future<void> deselect(int musicFolderId) async {
    if (!_selected.contains(musicFolderId)) return;
    _selected.remove(musicFolderId);
    notifyListeners();
    await _store();
  }

  Future<void> clear() async {
    _selected.clear();
    notifyListeners();
    await _store();
  }

  Future<void> _store() async {
    if (_selected.isEmpty) {
      await _keyValue.remove(_selectedKey);
      return;
    }
    await _keyValue.store(_selectedKey, _selected.toList());
  }

  @override
  void dispose() {
    _changedDebounce?.cancel();
    removeListener(_onChanged);
    removeListener(_onAuthChanged);
    super.dispose();
  }
}
