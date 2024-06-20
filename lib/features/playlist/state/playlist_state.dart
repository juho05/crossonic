part of 'playlist_cubit.dart';

class PlaylistState extends Equatable {
  const PlaylistState({
    required this.status,
    required this.reorderEnabled,
    required this.id,
    required this.name,
    required this.songCount,
    required this.duration,
    required this.coverID,
    required this.songs,
  });

  final FetchStatus status;
  final bool reorderEnabled;
  final String id;
  final String name;
  final int songCount;
  final Duration duration;
  final String? coverID;
  final List<Media> songs;

  PlaylistState copyWith({
    FetchStatus? status,
    bool? reorderEnabled,
    String? id,
    String? name,
    int? songCount,
    Duration? duration,
    required String? coverID,
    List<Media>? songs,
  }) {
    return PlaylistState(
      status: status ?? this.status,
      reorderEnabled: reorderEnabled ?? this.reorderEnabled,
      id: id ?? this.id,
      name: name ?? this.name,
      songCount: songCount ?? this.songCount,
      duration: duration ?? this.duration,
      coverID: coverID,
      songs: songs ?? this.songs,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reorderEnabled,
        id,
        name,
        songCount,
        duration,
        coverID,
        songs,
      ];
}
