/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/throttle.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class NowPlayingViewModel extends ChangeNotifier {
  final FavoritesRepository _favoritesRepository;
  final PlaybackManager _playbackManager;
  late final StreamSubscription _currentSongSubscription;
  late final StreamSubscription _playbackStatusSubscription;
  late final StreamSubscription _loopSubscription;
  late final StreamSubscription _volumeSubscription;
  late final StreamSubscription _positionUpdateSubscription;

  final BehaviorSubject<({Duration position, Duration? bufferedPosition})>
  _position = BehaviorSubject.seeded((
    position: Duration.zero,
    bufferedPosition: null,
  ));

  ValueStream<({Duration position, Duration? bufferedPosition})> get position =>
      _position.stream;

  Song? _song;

  Song? get song => _song;

  Queue? _currentQueue;

  String get currentQueueName => _currentQueue?.name ?? "Default";

  bool get isDefaultQueue => _currentQueue?.isDefault ?? true;

  bool _hasNamedQueues = false;

  bool get hasNamedQueues => _hasNamedQueues;

  String get songTitle => _song?.title ?? "";

  ({String id, String name})? get album => _song?.album;

  String get displayArtist => _song?.displayArtist ?? "";

  Duration? get duration => _song?.duration;

  String? get coverId => _song?.coverId;

  Iterable<({String id, String name})> get artists => _song?.artists ?? [];

  bool _favorite = false;

  bool get favorite => _favorite;

  PlaybackStatus _playbackStatus = PlaybackStatus.stopped;

  PlaybackStatus get playbackStatus => _playbackStatus;

  bool _loop = false;

  bool get loopEnabled => _loop;

  double _volume = 1;

  double get volume => _volume;
  Throttle1<double>? _volumeThrottle;

  set volume(double volume) {
    _volumeThrottle ??= Throttle1(
      action: (volume) {
        _playbackManager.player.volumeCubic = volume;
      },
      delay: const Duration(milliseconds: 100),
      leading: true,
      trailing: true,
    );
    _volume = volume;
    _volumeThrottle!.call(volume);
    notifyListeners();
  }

  NowPlayingViewModel({
    required FavoritesRepository favoritesRepository,
    required PlaybackManager playbackManager,
  }) : _favoritesRepository = favoritesRepository,
       _playbackManager = playbackManager,
       _volume = playbackManager.player.volumeLinear {
    _favoritesRepository.addListener(_onFavoriteChanged);
    _currentSongSubscription = _playbackManager.queue.current.listen(
      _onSongChanged,
    );
    _playbackStatusSubscription = _playbackManager.player.playbackStatus.listen(
      _onStatusChanged,
    );
    _loopSubscription = _playbackManager.queue.looping.listen((loop) {
      _loop = loop;
      notifyListeners();
    });
    _volumeSubscription = _playbackManager.player.volumeLinearStream.listen((
      _,
    ) {
      _volume = _playbackManager.player.volumeCubic;
      notifyListeners();
    });
    _positionUpdateSubscription = _playbackManager.player.positionUpdateStream
        .listen((_) => _updatePosition());
    _playbackManager.queue.addListener(_onQueueChanged);

    _onSongChanged(_playbackManager.queue.current.value);
    _onStatusChanged(_playbackManager.player.playbackStatus.value);
    _onQueueChanged();
    _loop = _playbackManager.queue.looping.value;
    _volume = _playbackManager.player.volumeCubic;
    notifyListeners();
  }

  Future<void> _onQueueChanged() async {
    bool changed = false;
    if (playbackStatus == PlaybackStatus.stopped) {
      _hasNamedQueues = await _playbackManager.queue.hasNamedQueues();
      changed = true;
    }
    if (_currentQueue?.id != _playbackManager.queue.currentQueueId) {
      _currentQueue = await _playbackManager.queue.getCurrentQueue();
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }

  void toggleLoop() async {
    _playbackManager.queue.setLoop(!_loop);
  }

  Future<Result<void>> toggleFavorite() async {
    if (_song == null) return const Result.ok(null);
    return await _favoritesRepository.setFavorite(
      FavoriteType.song,
      _song!.id,
      !favorite,
    );
  }

  Future<void> playPause() async {
    if (playbackStatus == PlaybackStatus.playing) {
      await _playbackManager.player.pause();
    } else {
      await _playbackManager.player.play();
    }
  }

  Future<void> playNext() async {
    await _playbackManager.playNext();
  }

  Future<void> playPrev() async {
    await _playbackManager.playPrev();
  }

  Future<void> seek(Duration pos) async {
    await _playbackManager.player.seek(pos);
  }

  void addToQueue(bool priority) {
    if (_song == null) return;
    _playbackManager.queue.add(_song!, priority);
  }

  Timer? _positionTimer;
  Timer? _bufferedPositionTimer;
  Duration? _bufferedPosition;

  Future<void> _onStatusChanged(PlaybackStatus status) async {
    _playbackStatus = status;
    notifyListeners();
    if (status == PlaybackStatus.stopped) {
      _hasNamedQueues = await _playbackManager.queue.hasNamedQueues();
      notifyListeners();
    }

    if (status == PlaybackStatus.playing) {
      _positionTimer ??= Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => _updatePosition(),
      );
      _bufferedPositionTimer ??= Timer.periodic(
        const Duration(milliseconds: 500),
        (_) async =>
            _bufferedPosition = await _playbackManager.player.bufferedPosition,
      );
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
      _bufferedPositionTimer?.cancel();
      _bufferedPositionTimer = null;
      _bufferedPosition = await _playbackManager.player.bufferedPosition;
      _updatePosition();
    }
  }

  void _onSongChanged(Song? song) {
    _updatePosition();
    _song = song;
    if (_song == null) {
      _favorite = false;
      return;
    }
    _favorite = _favoritesRepository.isFavorite(FavoriteType.song, _song!.id);
    notifyListeners();
  }

  void _updatePosition() async {
    _position.add((
      position: _playbackManager.player.position,
      bufferedPosition: _bufferedPosition,
    ));
  }

  void _onFavoriteChanged() {
    if (_song == null) return;
    bool old = _favorite;
    _favorite = _favoritesRepository.isFavorite(FavoriteType.song, _song!.id);
    if (old == _favorite) return;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    _favoritesRepository.removeListener(_onFavoriteChanged);
    _playbackManager.queue.removeListener(_onQueueChanged);
    await _positionUpdateSubscription.cancel();
    await _volumeSubscription.cancel();
    await _loopSubscription.cancel();
    await _currentSongSubscription.cancel();
    await _playbackStatusSubscription.cancel();
    _positionTimer?.cancel();
    _bufferedPositionTimer?.cancel();
    super.dispose();
  }
}
