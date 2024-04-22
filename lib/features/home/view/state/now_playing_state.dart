part of 'now_playing_cubit.dart';

class NowPlayingState extends Equatable {
  final String songID;
  final String songName;
  final String artist;
  final String album;
  final Duration duration;
  final String coverArtURL;
  bool get hasMedia => songID != "";

  final CrossonicPlaybackState playbackState;

  const NowPlayingState({
    this.songID = "",
    this.songName = "",
    this.artist = "",
    this.album = "",
    this.duration = Duration.zero,
    this.coverArtURL = "",
    required this.playbackState,
  });

  NowPlayingState copyWith({
    String? songID,
    String? songName,
    String? artist,
    String? album,
    Duration? duration,
    String? coverArtURL,
    CrossonicPlaybackState? playbackState,
  }) {
    return NowPlayingState(
      songID: songID ?? this.songID,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverArtURL: coverArtURL ?? this.coverArtURL,
      playbackState: playbackState ?? this.playbackState,
    );
  }

  @override
  List<Object> get props => [
        songID,
        songName,
        artist,
        album,
        duration,
        coverArtURL,
        playbackState,
      ];
}