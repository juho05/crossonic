import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

enum CrossonicPlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
}

class CrossonicPlaybackState extends Equatable {
  final CrossonicPlaybackStatus status;
  final Duration position;

  const CrossonicPlaybackState({
    required this.status,
    this.position = Duration.zero,
  });

  CrossonicPlaybackState copyWith({
    CrossonicPlaybackStatus? status,
    Duration? position,
  }) =>
      CrossonicPlaybackState(
        status: status ?? this.status,
        position: position ?? this.position,
      );

  @override
  List<Object?> get props => [status, position];
}

abstract interface class CrossonicAudioHandler {
  MediaQueue get mediaQueue;
  BehaviorSubject<CrossonicPlaybackState> get crossonicPlaybackStatus;

  Future<void> playPause();
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seek(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> dispose();
  Future<Uri> getCoverArtURL(String id, [int? size]);
}
