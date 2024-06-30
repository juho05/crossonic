part of 'playlists_cubit.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;
  final Map<String, bool> playlistDownloads;

  const PlaylistsState({
    required this.playlists,
    required this.playlistDownloads,
  });

  PlaylistsState copyWith({
    FetchStatus? status,
    List<Playlist>? playlists,
    Map<String, bool>? playlistDownloads,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      playlistDownloads: playlistDownloads ?? this.playlistDownloads,
    );
  }

  @override
  List<Object> get props => [playlists, playlistDownloads];
}
