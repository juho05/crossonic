part of 'now_playing_cubit.dart';

class NowPlayingState extends Equatable {
  final String songID;
  final String songName;
  final String artist;
  final String artistID;
  final String album;
  final String albumID;
  final Duration duration;
  final String coverArtID;
  bool get hasMedia => songID != "";

  final CrossonicPlaybackState playbackState;

  const NowPlayingState({
    this.songID = "",
    this.songName = "",
    this.artist = "",
    this.artistID = "",
    this.album = "",
    this.albumID = "",
    this.duration = Duration.zero,
    this.coverArtID = "",
    required this.playbackState,
  });

  NowPlayingState copyWith({
    String? songID,
    String? songName,
    String? artist,
    String? artistID,
    String? album,
    String? albumID,
    Duration? duration,
    String? coverArtID,
    String? coverArtURLSmall,
    CrossonicPlaybackState? playbackState,
  }) {
    return NowPlayingState(
      songID: songID ?? this.songID,
      songName: songName ?? this.songName,
      artist: artist ?? this.artist,
      artistID: artistID ?? this.artistID,
      album: album ?? this.album,
      albumID: albumID ?? this.albumID,
      duration: duration ?? this.duration,
      coverArtID: coverArtID ?? this.coverArtID,
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
        coverArtID,
        playbackState,
      ];
}
