/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:math';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/material.dart';

enum SongsPageMode { all, random, favorites, genre }

class SongsViewModel extends ChangeNotifier {
  final SubsonicRepository _subsonic;
  final PlaybackManager _playbackManager;

  static final int _pageSize = 500;

  bool get supportsAllMode => _subsonic.supports.emptySearchString;

  SongsPageMode _mode = SongsPageMode.random;

  SongsPageMode get mode => _mode;

  set mode(SongsPageMode mode) {
    if (mode == SongsPageMode.genre) {
      throw Exception("genre mode must be set via constructor");
    }
    if (!supportsAllMode && mode == SongsPageMode.all) {
      mode = SongsPageMode.random;
    }
    _mode = mode;
    refresh();
  }

  final List<Song> songs = [];

  bool _reachedEnd = false;

  int get _nextPage => (songs.length / _pageSize).ceil();

  FetchStatus _status = FetchStatus.initial;

  FetchStatus get status => _status;

  final String _genre;
  final String? _initialSeed;

  StreamSubscription? _musicFolderSub;

  SongsViewModel({
    required SubsonicRepository subsonic,
    required PlaybackManager playbackManager,
    required SongsPageMode mode,
    required MusicFoldersRepository musicFolders,
    String? initialSeed,
  }) : _subsonic = subsonic,
       _playbackManager = playbackManager,
       _genre = "",
       _initialSeed =
           subsonic.supports.randomSeed && mode == SongsPageMode.random
           ? initialSeed
           : null {
    if (mode == SongsPageMode.genre) {
      throw Exception(
        "cannot set genre page mode via default constructor, use genre constructor instead",
      );
    }
    this.mode = mode;
    _musicFolderSub = musicFolders.debounced.listen((event) {
      refresh(keepSeed: true);
    });
  }

  SongsViewModel.genre({
    required SubsonicRepository subsonic,
    required PlaybackManager playbackManager,
    required MusicFoldersRepository musicFolders,
    required String genre,
  }) : _subsonic = subsonic,
       _playbackManager = playbackManager,
       _genre = genre,
       _initialSeed = null {
    _mode = SongsPageMode.genre;
    refresh();
    _musicFolderSub = musicFolders.debounced.listen((event) {
      refresh(keepSeed: true);
    });
  }

  Future<void> nextPage() async {
    if (_reachedEnd ||
        (_mode == SongsPageMode.random && !_subsonic.supports.randomSeed) ||
        _mode == SongsPageMode.favorites) {
      return;
    }
    return await _fetch(_nextPage);
  }

  Future<void> refresh({bool keepSeed = false}) async {
    return await _fetch(0, keepSeedOnRefresh: keepSeed);
  }

  void play() async {
    _playbackManager.player.playOnNextMediaChange();
    _playbackManager.queue.replace(songs);
  }

  Future<Result<void>> shuffle() async {
    Iterable<Song> s;
    if (_mode == SongsPageMode.all || _mode == SongsPageMode.random) {
      final result = await _subsonic.getRandomSongs(count: 500);
      switch (result) {
        case Err():
          return Result.error(result.error);
        case Ok():
      }
      s = result.value;
    } else if (_mode == SongsPageMode.genre && _subsonic.supports.getSongs) {
      final result = await _subsonic.getSongs(
        count: 500,
        genres: [_genre],
        sort: SongsSortMode.random,
      );
      switch (result) {
        case Err():
          return Result.error(result.error);
        case Ok():
      }
      s = result.value;
    } else {
      s = List.of(songs)..shuffle();
    }
    _playbackManager.player.playOnNextMediaChange();
    await _playbackManager.queue.replace(s);
    return const Result.ok(null);
  }

  void addAllToQueue(bool priority) async {
    _playbackManager.queue.addAll(songs, priority);
  }

  String? _seed;

  Future<void> _fetch(int page, {bool keepSeedOnRefresh = false}) async {
    if (_status == FetchStatus.loading) return;
    _status = FetchStatus.loading;

    if (page == 0 && _subsonic.supports.randomSeed) {
      if (_seed == null && _initialSeed != null) {
        _seed = _initialSeed;
      } else if (!keepSeedOnRefresh) {
        _seed = Random().nextDouble().toString();
      }
    }

    if (page * _pageSize < songs.length) {
      songs.removeRange(page * _pageSize, songs.length);
    }
    notifyListeners();
    final Result<Iterable<Song>> result;
    switch (_mode) {
      case SongsPageMode.random:
        result = await _subsonic.getRandomSongs(
          count: _pageSize,
          offset: page * _pageSize,
          seed: _seed,
        );
      case SongsPageMode.all:
        final r = await _subsonic.search(
          "",
          songCount: _pageSize,
          songOffset: page * _pageSize,
          albumCount: 0,
          artistCount: 0,
        );
        switch (r) {
          case Err():
            result = Result.error(r.error);
          case Ok():
            result = Result.ok(r.value.songs);
        }
      case SongsPageMode.favorites:
        result = await _subsonic.getStarredSongs();
      case SongsPageMode.genre:
        result = await _subsonic.getSongsByGenre(
          _genre,
          count: _pageSize,
          offset: page * _pageSize,
        );
    }
    switch (result) {
      case Err():
        _status = FetchStatus.failure;
        notifyListeners();
        return;
      case Ok():
    }
    _status = FetchStatus.success;
    _reachedEnd = result.value.length < _pageSize;
    songs.addAll(result.value);
    notifyListeners();
  }

  @override
  void dispose() {
    _musicFolderSub?.cancel();
    super.dispose();
  }
}
