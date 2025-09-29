import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart' as asv;
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/media_integration/media_integration.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';

class AudioServiceIntegration extends asv.BaseAudioHandler
    with asv.SeekHandler
    implements MediaIntegration {
  final PlaylistRepository _playlistRepository;

  Future<void> Function()? _onPlay;
  Future<void> Function()? _onPause;
  Future<void> Function(Duration position)? _onSeek;
  Future<void> Function()? _onPlayNext;
  Future<void> Function()? _onPlayPrev;
  Future<void> Function()? _onStop;

  AudioHandler? _audioHandler;

  AudioServiceIntegration({
    required PlaylistRepository playlistRepository,
  }) : _playlistRepository = playlistRepository;

  @override
  Future<void> ensureInitialized({
    required AudioHandler audioHandler,
    required Future<void> Function() onPlay,
    required Future<void> Function() onPause,
    required Future<void> Function(Duration position) onSeek,
    required Future<void> Function() onPlayNext,
    required Future<void> Function() onPlayPrev,
    required Future<void> Function() onStop,
  }) async {
    if (_audioHandler != null) return;
    _audioHandler = audioHandler;
    _audioHandler!.queue.looping.listen((loop) {
      playbackState.add(playbackState.value.copyWith(
        repeatMode: _audioHandler!.queue.looping.value
            ? asv.AudioServiceRepeatMode.all
            : asv.AudioServiceRepeatMode.none,
      ));
    });
    _onPlay = onPlay;
    _onPause = onPause;
    _onSeek = onSeek;
    _onPlayNext = onPlayNext;
    _onPlayPrev = onPlayPrev;
    _onStop = onStop;
  }

  @override
  Future<List<asv.MediaItem>> getChildren(String parentMediaId,
      [Map<String, dynamic>? options]) async {
    Log.trace("Android Auto requested media children: $parentMediaId");
    if (parentMediaId == "root") {
      return [
        const asv.MediaItem(
            id: "playlists",
            title: "Playlists",
            playable: false,
            extras: {
              // DESCRIPTION_EXTRAS_KEY_CONTENT_STYLE_BROWSABLE: DESCRIPTION_EXTRAS_VALUE_CONTENT_STYLE_GRID_ITEM
              "android.media.browse.CONTENT_STYLE_BROWSABLE_HINT": 2,
            })
      ];
    }
    if (parentMediaId == "playlists") {
      final result = await _playlistRepository.getPlaylists();
      switch (result) {
        case Err():
          Log.error("Failed to get playlists", e: result.error);
          return [];
        case Ok():
      }
      return result.value
          .map((p) => asv.MediaItem(
                id: p.id,
                title: p.name,
                playable: false,
                displayDescription: "Songs: ${p.songCount}",
                artUri: _playlistRepository.getPlaylistCoverUri(p, size: 512),
              ))
          .toList();
    }
    return [
      asv.MediaItem(
        id: "playlist;play;$parentMediaId",
        title: "Play",
        playable: true,
      ),
      asv.MediaItem(
        id: "playlist;shuffle;$parentMediaId",
        title: "Shuffle",
        playable: true,
      ),
    ];
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    Log.debug("Android Auto requested to play media by id: $mediaId");
    if (mediaId.startsWith("playlist;")) {
      final parts = mediaId.split(";");
      final result = await _playlistRepository.getPlaylist(parts[2]);
      switch (result) {
        case Err():
          throw result.error;
        case Ok():
      }
      if (result.value == null) {
        throw Exception("playlist not found");
      }
      final songs = result.value!.tracks;
      if (parts[1] == "shuffle") {
        songs.shuffle();
      }
      _audioHandler?.playOnNextMediaChange();
      _audioHandler?.queue.replace(songs);
      return;
    }
  }

  @override
  Future<void> play() async {
    Log.debug(
        "audio_service received play action, current status: ${_audioHandler!.playbackStatus.value.name}");
    if (_audioHandler!.playbackStatus.value == PlaybackStatus.stopped) {
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: asv.AudioProcessingState.idle,
        playing: false,
      ));
      return;
    }
    return _onPlay!();
  }

  @override
  Future<void> pause() async {
    Log.debug(
        "audio_service received pause action, current status: ${_audioHandler!.playbackStatus.value.name}");
    await _onPause!();
  }

  @override
  Future<void> seek(Duration position) async {
    Log.debug("audio_service received seek action to position $position");
    await _onSeek!(position);
  }

  @override
  Future<void> skipToNext() async {
    Log.trace("audio_service received skipToNext action");
    await _onPlayNext!();
  }

  @override
  Future<void> skipToPrevious() async {
    Log.debug("audio_service received skipToPrevious action");
    await _onPlayPrev!();
  }

  @override
  Future<void> stop() async {
    Log.debug("audio_service received stop action");
    await _onStop!();
  }

  @override
  void updateMedia(Song? song, Uri? coverArt) {
    Log.trace(
        "setting audio_service media to song ${song?.id} with cover: ${SubsonicService.sanitizeUrl(coverArt)}");
    if (song == null) {
      if (!kIsWeb && Platform.isAndroid) {
        mediaItem.add(const asv.MediaItem(id: "", title: "No media"));
      } else {
        mediaItem.add(null);
      }
      playbackState.add(playbackState.value.copyWith(
        controls: [],
        systemActions: {},
        androidCompactActionIndices: [],
        processingState: asv.AudioProcessingState.idle,
        playing: false,
      ));
      _positionTimer?.cancel();
      _positionTimer = null;
    } else {
      if (playbackState.value.controls.isEmpty) {
        playbackState.add(playbackState.value.copyWith(
          controls: [
            asv.MediaControl.pause,
            asv.MediaControl.play,
            asv.MediaControl.skipToNext,
            asv.MediaControl.skipToPrevious,
            asv.MediaControl.stop,
          ],
          systemActions: {
            asv.MediaAction.pause,
            asv.MediaAction.play,
            asv.MediaAction.playPause,
            asv.MediaAction.seek,
            asv.MediaAction.seekForward,
            asv.MediaAction.seekBackward,
            asv.MediaAction.skipToNext,
            asv.MediaAction.skipToPrevious,
            asv.MediaAction.stop,
            asv.MediaAction.setRepeatMode,
          },
          androidCompactActionIndices: [0, 1],
          repeatMode: _audioHandler!.queue.looping.value
              ? asv.AudioServiceRepeatMode.all
              : asv.AudioServiceRepeatMode.none,
        ));
      }
      mediaItem.add(asv.MediaItem(
        id: song.id,
        title: song.title,
        album: song.album?.name,
        artUri: coverArt,
        artist: song.displayArtist,
        duration: song.duration,
        genre: song.genres.firstOrNull,
        playable: true,
      ));
    }
  }

  Timer? _positionTimer;
  (DateTime, Duration) _positionUpdate = (DateTime.now(), Duration.zero);

  @override
  void updatePlaybackState(PlaybackStatus status) {
    Log.trace("setting audio_service playback state to ${status.name}");
    switch (status) {
      case PlaybackStatus.playing:
        playbackState.add(playbackState.value.copyWith(
            playing: true,
            processingState: asv.AudioProcessingState.ready,
            updatePosition: _calculatePosition()));
      case PlaybackStatus.paused:
        playbackState.add(playbackState.value.copyWith(
            playing: false,
            processingState: asv.AudioProcessingState.ready,
            updatePosition: _calculatePosition()));
      case PlaybackStatus.loading:
        playbackState.add(playbackState.value.copyWith(
            playing: false,
            processingState: asv.AudioProcessingState.loading,
            updatePosition: _calculatePosition()));
      case PlaybackStatus.stopped:
        playbackState.add(playbackState.value.copyWith(
            playing: false, processingState: asv.AudioProcessingState.idle));
    }

    // TODO test whether periodic updates are unnecessary on other platforms
    if ((kIsWeb || !Platform.isAndroid) && status == PlaybackStatus.playing) {
      _positionTimer ??=
          Timer.periodic(const Duration(seconds: 1), (_) => _updatePosition());
    } else {
      _positionTimer?.cancel();
      _positionTimer = null;
    }
  }

  @override
  void updatePosition(Duration position) {
    Log.trace("updating audio_service position to $position");
    _positionUpdate = (DateTime.now(), position);
    _updatePosition();
  }

  void _updatePosition() {
    playbackState.add(playbackState.value.copyWith(
      updatePosition: _calculatePosition(),
    ));
  }

  Duration _calculatePosition() {
    Duration position = _positionUpdate.$2;
    if (playbackState.value.playing) {
      position += DateTime.now().difference(_positionUpdate.$1);
    }
    return position;
  }

  @override
  Future<void> setRepeatMode(asv.AudioServiceRepeatMode repeatMode) async {
    final loop = repeatMode != asv.AudioServiceRepeatMode.none;
    Log.trace(
        "received audio_service repeat mode ${repeatMode.name}, setting loop to $loop");
    _audioHandler!.queue.setLoop(loop);
  }
}
