/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:collection';

import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/subsonic/models/music_folder.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class MusicFoldersViewModel extends ChangeNotifier {
  static const int ALL_ID = -1;

  final SubsonicRepository _subsonic;
  final MusicFoldersRepository _repo;

  FetchStatus _status = FetchStatus.initial;

  FetchStatus get status => _status;

  bool get supportsMultiSelect => _subsonic.supports.multipleActiveMusicFolders;

  List<MusicFolder> _musicFolders = [];

  List<MusicFolder> get musicFolders => UnmodifiableListView(_musicFolders);

  Set<int> get selected => _repo.selected;

  MusicFoldersViewModel({
    required SubsonicRepository subsonic,
    required MusicFoldersRepository repo,
  }) : _subsonic = subsonic,
       _repo = repo {
    _repo.addListener(notifyListeners);
    _load();
  }

  Future<void> _load() async {
    _status = FetchStatus.loading;
    notifyListeners();

    final result = await _repo.getMusicFolders();
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        Log.error("Failed to load music folders", e: result.error);
        notifyListeners();
        return;
      case Ok():
    }
    _musicFolders = result.value;
    _status = FetchStatus.success;
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    if (id == ALL_ID) {
      await select(id);
      return;
    }
    if (selected.contains(id)) {
      await _repo.deselect(id);
    } else {
      await _repo.select(id);
    }
  }

  Future<void> select(int id) async {
    if (id == ALL_ID) {
      await _repo.clear();
      return;
    }
    if (supportsMultiSelect) {
      await _repo.select(id);
    } else {
      await _repo.setSelected({id});
    }
  }

  Future<void> deselect(int id) async {
    await _repo.deselect(id);
  }

  Future<void> clearSelection() async {
    await _repo.clear();
  }

  @override
  void dispose() {
    _repo.removeListener(notifyListeners);
    super.dispose();
  }
}
