part of 'random_songs_cubit.dart';

class RandomSongsState extends Equatable {
  const RandomSongsState(
      {this.status = FetchStatus.initial, this.songs = const []});

  final FetchStatus status;
  final List<Media> songs;

  RandomSongsState copyWith({
    FetchStatus? status,
    List<Media>? songs,
  }) {
    return RandomSongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
    );
  }

  @override
  List<Object> get props => [status, songs];
}
