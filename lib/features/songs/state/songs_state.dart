part of 'songs_cubit.dart';

class SongsState extends Equatable {
  const SongsState({
    this.status = FetchStatus.initial,
    this.songs = const [],
    this.reachedEnd = false,
  });

  final FetchStatus status;
  final List<Media> songs;
  final bool reachedEnd;

  SongsState copyWith({
    FetchStatus? status,
    List<Media>? songs,
    bool? reachedEnd,
  }) {
    return SongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      reachedEnd: reachedEnd ?? this.reachedEnd,
    );
  }

  @override
  List<Object> get props => [status, songs, reachedEnd];
}
