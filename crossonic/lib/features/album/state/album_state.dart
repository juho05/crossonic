part of 'album_cubit.dart';

class Track extends Equatable {
  final String id;
  final int number;
  final String title;
  final Duration duration;

  const Track({
    required this.id,
    required this.number,
    required this.title,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, number, title, duration];
}

class AlbumState extends Equatable {
  const AlbumState({
    required this.status,
    required this.id,
    required this.name,
    required this.year,
    required this.coverID,
    required this.artists,
    required this.songs,
    required this.subsonicSongs,
  });

  final FetchStatus status;
  final String id;
  final String name;
  final int year;
  final String coverID;
  final Artists artists;
  final List<Track> songs;
  final List<Media> subsonicSongs;

  AlbumState copyWith({
    FetchStatus? status,
    String? id,
    String? name,
    int? year,
    String? coverID,
    Artists? artists,
    String? artistDisplayName,
    List<Track>? songs,
    List<Media>? subsonicSongs,
  }) {
    return AlbumState(
      status: status ?? this.status,
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      coverID: coverID ?? this.coverID,
      artists: artists ?? this.artists,
      songs: songs ?? this.songs,
      subsonicSongs: subsonicSongs ?? this.subsonicSongs,
    );
  }

  @override
  List<Object> get props =>
      [status, id, name, year, coverID, artists, songs, subsonicSongs];
}
