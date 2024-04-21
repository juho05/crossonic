part of 'home_cubit.dart';

enum RandomSongsStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState(
      {this.randomSongsStatus = RandomSongsStatus.initial,
      this.randomSongs = const []});

  final RandomSongsStatus randomSongsStatus;
  final List<Child> randomSongs;

  HomeState copyWith({
    RandomSongsStatus? randomSongsStatus,
    List<Child>? randomSongs,
  }) {
    return HomeState(
      randomSongsStatus: randomSongsStatus ?? this.randomSongsStatus,
      randomSongs: randomSongs ?? this.randomSongs,
    );
  }

  @override
  List<Object> get props => [randomSongsStatus, randomSongs];
}
