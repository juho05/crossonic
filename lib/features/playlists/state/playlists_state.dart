part of 'playlists_cubit.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;

  const PlaylistsState({
    required this.playlists,
  });

  PlaylistsState copyWith({
    FetchStatus? status,
    List<Playlist>? playlists,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  List<Object> get props => [playlists];
}
