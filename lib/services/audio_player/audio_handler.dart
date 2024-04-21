import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/src/subjects/behavior_subject.dart';

class CrossonicAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final SubsonicRepository _subsonicRepository;
  late final AudioPlayer _player;
  CrossonicAudioHandler({
    AudioPlayer? player,
    required SubsonicRepository subsonicRepository,
  }) : _subsonicRepository = subsonicRepository {
    _player = player ?? AudioPlayer();

    _player.playerStateStream.listen((event) {
      playbackState.add(playbackState.value.copyWith(
        playing: event.playing,
        processingState: switch (event.processingState) {
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.completed => AudioProcessingState.completed,
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.ready => AudioProcessingState.ready,
        },
        controls: [
          if (event.processingState == ProcessingState.ready) MediaControl.play,
          if (event.playing) MediaControl.pause,
          if (event.processingState != ProcessingState.idle) MediaControl.stop,
        ],
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        systemActions: {
          if (event.processingState != ProcessingState.idle) MediaAction.seek,
        },
      ));
    });
  }

  @override
  Future<void> playFromMediaId(String mediaId,
      [Map<String, dynamic>? extras]) async {
    final url = await _subsonicRepository.getStreamURL(songID: mediaId);
    await playFromUri(url, {"id": mediaId});
  }

  @override
  Future<void> playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    Duration? duration = await _player.setUrl(uri.toString());
    mediaItem.add(MediaItem(
      id: extras?["id"] ?? "",
      title: "Demo Song",
      album: "Demo Album 1234",
      artist: "Demo Artist 1234",
      duration: duration,
    ));
    if (Platform.isWindows) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return play();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      return _player.pause();
    }
    return _player.play();
  }

  @override
  Future<void> play() async {
    return _player.play();
  }

  @override
  Future<void> pause() async {
    return _player.pause();
  }

  @override
  Future<void> stop() async {
    return _player.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    return _player.seek(position);
  }

  Future<void> dispose() {
    return _player.dispose();
  }
}
