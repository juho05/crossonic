import 'dart:async';
import 'dart:io';

import 'package:crossonic/data/repositories/audio/queue/local_queue.dart';
import 'package:crossonic/data/repositories/audio/queue/media_queue.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/audio_players/player.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum PlaybackStatus {
  stopped,
  loading,
  playing,
  paused,
}

class AudioHandler {
  final AuthRepository _auth;
  final SubsonicService _subsonic;

  final AudioPlayer _player;
  StreamSubscription? _playerEventSubscription;

  final MediaIntegration _integration;

  final BehaviorSubject<void> _queueChanged = BehaviorSubject();
  Stream<void> get queueChanged => _queueChanged.stream;

  final BehaviorSubject<PlaybackStatus> _playbackStatus =
      BehaviorSubject.seeded(PlaybackStatus.stopped);
  ValueStream<PlaybackStatus> get playbackStatus => _playbackStatus.stream;

  final BehaviorSubject<({Duration position, Duration? bufferedPosition})>
      _position =
      BehaviorSubject.seeded((position: Duration.zero, bufferedPosition: null));
  ValueStream<({Duration position, Duration? bufferedPosition})> get position =>
      _position.stream;

  MediaQueue _queue = LocalQueue();
  StreamSubscription? _currentSubscription;
  StreamSubscription? _nextSubscription;

  Duration _positionOffset = Duration.zero;
  Timer? _positionTimer;

  Timer? _disposePlayerTimer;

  bool _playOnNextMediaChange = false;

  AudioHandler({
    required AudioPlayer player,
    required MediaIntegration integration,
    required AuthRepository authRepository,
    required SubsonicService subsonicService,
  })  : _player = player,
        _integration = integration,
        _auth = authRepository,
        _subsonic = subsonicService {
    queue = _queue;

    _auth.addListener(_authChanged);

    _integration.ensureInitialized(
      audioHandler: this,
      onPause: pause,
      onPlay: play,
      onPlayNext: playNext,
      onPlayPrev: playPrev,
      onSeek: seek,
      onStop: stop,
    );
    _integration.updateMedia(null, null);

    _playerEventSubscription = _player.eventStream.listen(_playerEvent);
  }

  // ================ playback controls ================

  void playOnNextMediaChange() {
    _playOnNextMediaChange = true;
  }

  Future<void> play() async {
    await _ensurePlayerLoaded();
    await _player.play();
  }

  Future<void> pause() async {
    await _ensurePlayerLoaded();
    await _player.pause();
  }

  Future<void> stop() async {
    _playOnNextMediaChange = false;
    _stopPositionTimer();
    _integration.updateMedia(null, null);
    _integration.updatePosition(Duration.zero);
    _integration.updatePlaybackState(PlaybackStatus.stopped);
    _positionOffset = Duration.zero;
    _queue.clear();
    await _disposePlayer();
  }

  Future<void> seek(Duration pos) async {
    final song = _queue.current.value.song;
    if (song == null) return;
    await _ensurePlayerLoaded();
    if (_player.canSeek && _positionOffset == Duration.zero) {
      await _player.seek(pos);
    } else {
      pos = Duration(seconds: pos.inSeconds);
      await _player.setCurrent(_getStreamUri(song, pos));
      _positionOffset = pos;
    }
    _position.add((position: pos, bufferedPosition: pos));
  }

  Future<void> playNext() async {
    if (!_queue.canAdvance) return;
    _queue.skipNext();
  }

  Future<void> playPrev() async {
    if (position.value.position.inSeconds > 3 || !_queue.canGoBack) {
      await seek(Duration.zero);
      return;
    }
    _queue.skipPrev();
  }

  // ================ callbacks ================

  Future<void> _playerEvent(AudioPlayerEvent event) async {
    if (!_player.initialized) return;
    if (event == AudioPlayerEvent.advance) {
      _queue.advance();
      return;
    }
    var status = switch (event) {
      AudioPlayerEvent.stopped => PlaybackStatus.stopped,
      AudioPlayerEvent.loading => PlaybackStatus.loading,
      AudioPlayerEvent.playing => PlaybackStatus.playing,
      AudioPlayerEvent.paused => PlaybackStatus.paused,
      AudioPlayerEvent.advance => throw Exception("should never happen"),
    };
    if (_queue.length == 0) {
      status = PlaybackStatus.stopped;
    }
    if (status == _playbackStatus.value) return;
    if (status == PlaybackStatus.stopped) {
      await stop();
      return;
    }
    _integration.updatePlaybackState(status);
    _playbackStatus.add(status);
    _updatePosition(true);
    if (status == PlaybackStatus.playing) {
      _startPositionTimer();
    } else {
      _stopPositionTimer();
    }

    if (status != PlaybackStatus.playing && status != PlaybackStatus.loading) {
      // web browsers stop media os integration without active player
      if (!kIsWeb) {
        _disposePlayerTimer ??=
            Timer(const Duration(minutes: 1), _disposePlayer);
      }
    } else {
      _disposePlayerTimer?.cancel();
      _disposePlayerTimer = null;
    }
  }

  Future<void> _onCurrentChanged(Song? song, bool fromAdvance) async {
    final playAfterChange = _playOnNextMediaChange;
    _playOnNextMediaChange = false;
    if (song == null) {
      await stop();
      return;
    }
    _positionOffset = Duration.zero;

    await _ensurePlayerLoaded(false);

    if (!fromAdvance) {
      await _player.setCurrent(_getStreamUri(song));
      if (playAfterChange) {
        await _player.play();
      }
    }
    _integration.updateMedia(song, _getCoverUri(song.coverId));
  }

  Future<void> _onNextChanged(Song? song) async {
    if (!_player.initialized && song != null) {
      await _ensurePlayerLoaded();
    }
    await _player.setNext(song != null ? _getStreamUri(song) : null);
  }

  void _onQueueChanged() => _queueChanged.add(null);

  Future<void> _authChanged() async {
    if (_auth.isAuthenticated) return;
    if (playbackStatus.value != PlaybackStatus.stopped) {
      await stop();
    }
  }

  // ================ helpers ================

  Future<void> _ensurePlayerLoaded([bool restorePlayerState = true]) async {
    if (_player.initialized) return;
    _player.init();
    if (restorePlayerState) {
      await _restorePlayerState();
    }
  }

  Future<void> _restorePlayerState() async {
    final current = _queue.current.value.song;
    final next = _queue.next.value;
    if (current != null) {
      _positionOffset = position.value.position;
      await _player.setCurrent(_getStreamUri(current, position.value.position));
      if (_playbackStatus.value == PlaybackStatus.playing) {
        await play();
      } else {
        await pause();
      }
    }
    if (next != null) {
      await _player.setNext(_getStreamUri(next));
    }
    if (current == null && next == null) {
      await stop();
    }
  }

  Future<void> _disposePlayer() async {
    if (!_player.initialized ||
        _playbackStatus.value == PlaybackStatus.playing ||
        _playbackStatus.value == PlaybackStatus.loading) {
      return;
    }
    await _player.dispose();
  }

  void _startPositionTimer() {
    if (_positionTimer != null) return;
    int counter = 0;
    _positionTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (!kIsWeb && Platform.isLinux) {
        counter++;
      }
      _updatePosition(counter % 5 == 0);
    });
  }

  Future<void> _updatePosition(bool updateNative) async {
    if (_playbackStatus.value == PlaybackStatus.stopped) {
      _position.add((position: Duration.zero, bufferedPosition: null));
      if (updateNative) {
        _integration.updatePosition(Duration.zero);
      }
      return;
    }
    if (_playbackStatus.value != PlaybackStatus.playing &&
        _playbackStatus.value != PlaybackStatus.paused) {
      return;
    }

    await _ensurePlayerLoaded();

    final pos = await _player.position + _positionOffset;
    final bufferedPos = await _player.bufferedPosition + _positionOffset;

    _position.add((position: pos, bufferedPosition: bufferedPos));
    if (updateNative) {
      _integration.updatePosition(pos, bufferedPos);
    }
  }

  void _stopPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = null;
  }

  Uri _getStreamUri(Song song, [Duration? offset]) {
    final query = _subsonic.generateQuery({
      "id": [song.id],
      "format": [], // TODO
      "maxBitRate": [], // TODO
      "timeOffset": offset != null ? [offset.inSeconds.toString()] : [],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/stream${Uri(queryParameters: query)}');
  }

  Uri? _getCoverUri(String? coverId) {
    if (coverId == null) return null;
    final query = _subsonic.generateQuery({
      "id": [coverId],
    }, _auth.con.auth);
    return Uri.parse(
        '${_auth.con.baseUri}/rest/getCoverArt${Uri(queryParameters: query)}');
  }

  // ================ queue ================

  set queue(MediaQueue queue) {
    _playOnNextMediaChange = false;

    _currentSubscription?.cancel();
    _nextSubscription?.cancel();
    _queue.removeListener(_onQueueChanged);

    _queue = queue;

    _currentSubscription = _queue.current.listen(
        (current) => _onCurrentChanged(current.song, current.fromAdvance));
    _nextSubscription = _queue.next.listen(_onNextChanged);
    _queue.addListener(_onQueueChanged);

    _loop.add(_queue.loop);

    _onQueueChanged();
  }

  final BehaviorSubject<bool> _loop = BehaviorSubject.seeded(false);
  ValueStream<bool> get loop => _loop.stream;

  void setLoop(bool loop) {
    _queue.loop = loop;
    _loop.add(loop);
  }

  void add(Song song, bool priority) {
    _queue.add(song, priority);
  }

  void addAll(Iterable<Song> songs, bool priority) {
    _queue.addAll(songs, priority);
  }

  bool get hasNext => _queue.canAdvance;

  bool get hasPrevious => _queue.canGoBack;

  void clear(
      {bool queue = true, int fromIndex = 0, bool priorityQueue = true}) {
    _queue.clear(
        queue: queue, fromIndex: fromIndex, priorityQueue: priorityQueue);
  }

  final BehaviorSubject<Song?> _currentSong = BehaviorSubject.seeded(null);
  ValueStream<Song?> get currentSong => _currentSong.stream;

  void goTo(int index) {
    _queue.goTo(index);
  }

  void goToPriority(int index) {
    _queue.goToPriority(index);
  }

  void insert(int index, Song song) {
    _queue.insert(index, song);
  }

  void insertAll(int index, Iterable<Song> songs) {
    _queue.insertAll(index, songs);
  }

  int get queueIndex => _queue.currentIndex;

  Iterable<Song> get priorityQueue => _queue.priority;
  int get priorityLength => _queue.priorityLength;

  Iterable<Song> get regularQueue => _queue.regular;
  int get queueLength => _queue.length;

  void remove(int index) {
    _queue.remove(index);
  }

  void removeFromPriorityQueue(int index) {
    _queue.removeFromPriorityQueue(index);
  }

  void replace(Iterable<Song> songs, [int startIndex = 0]) {
    _queue.replace(songs, startIndex);
  }

  void shuffleFollowing() {
    _queue.shuffleFollowing();
  }

  void shufflePriority() {
    _queue.shufflePriority();
  }

  void skipNext() {
    _queue.skipNext();
  }

  void skipPrev() {
    _queue.skipPrev();
  }

  // dispose
  Future<void> dispose() async {
    await stop();
    // dispose queue
    await _currentSubscription?.cancel();
    await _nextSubscription?.cancel();
    _queue.dispose();

    // dispose player
    await _playerEventSubscription?.cancel();
    await _player.dispose();

    _auth.removeListener(_authChanged);
  }
}
