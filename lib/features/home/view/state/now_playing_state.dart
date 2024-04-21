part of 'now_playing_cubit.dart';

class NowPlayingState extends Equatable {
  final String songID;
  final String songName;
  final String artist;
  final String album;
  final Duration duration;
  bool get hasMedia => songID != "";

  final bool playing;
  final Duration position;

  const NowPlayingState({
    this.songID = "",
    this.songName = "",
    this.artist = "",
    this.album = "",
    this.duration = Duration.zero,
    required this.playing,
    this.position = Duration.zero,
  });

  NowPlayingState copyWith({
    String? songID,
    String? songName,
    String? artist,
    String? album,
    Duration? duration,
    bool? playing,
    Duration? position,
  }) {
    return NowPlayingState(
      songID: songID ?? this.songID,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
      position: position ?? this.position,
    );
  }

  @override
  List<Object> get props =>
      [songID, songName, artist, album, duration, playing, position];
}
