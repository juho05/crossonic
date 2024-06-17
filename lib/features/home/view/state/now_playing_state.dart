part of 'now_playing_cubit.dart';

class NowPlayingState extends Equatable {
  final String songID;
  final String songName;
  final Artists artists;
  final String album;
  final String albumID;
  final Duration duration;
  final String coverArtID;
  final Media? media;
  bool get hasMedia => songID != "";

  final CrossonicPlaybackState playbackState;

  const NowPlayingState({
    this.songID = "",
    this.songName = "",
    this.artists = const Artists(artists: [], displayName: ""),
    this.album = "",
    this.albumID = "",
    this.duration = Duration.zero,
    this.coverArtID = "",
    this.media,
    required this.playbackState,
  });

  NowPlayingState copyWith({
    String? songID,
    String? songName,
    Artists? artists,
    String? album,
    String? albumID,
    Duration? duration,
    String? coverArtID,
    String? coverArtURLSmall,
    CrossonicPlaybackState? playbackState,
    required Media? media,
  }) {
    return NowPlayingState(
      songID: songID ?? this.songID,
      songName: songName ?? this.songName,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      albumID: albumID ?? this.albumID,
      duration: duration ?? this.duration,
      coverArtID: coverArtID ?? this.coverArtID,
      playbackState: playbackState ?? this.playbackState,
      media: media,
    );
  }

  @override
  List<Object?> get props => [
        songID,
        songName,
        artists,
        album,
        duration,
        coverArtID,
        playbackState,
        media,
      ];
}
