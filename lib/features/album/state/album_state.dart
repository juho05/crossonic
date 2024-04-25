part of 'album_cubit.dart';

class Track extends Equatable {
  final String id;
  final int number;
  final String title;
  final Duration duration;
  final bool isFavorite;

  const Track({
    required this.id,
    required this.number,
    required this.title,
    required this.duration,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [id, number, title, duration, isFavorite];
}

class AlbumState extends Equatable {
  const AlbumState({
    required this.status,
    required this.id,
    required this.name,
    required this.year,
    required this.coverID,
    required this.artistID,
    required this.artistName,
    required this.songs,
    required this.subsonicSongs,
  });

  final FetchStatus status;
  final String id;
  final String name;
  final int year;
  final String coverID;
  final String artistID;
  final String artistName;
  final List<Track> songs;
  final List<Media> subsonicSongs;

  AlbumState copyWith({
    FetchStatus? status,
    String? id,
    String? name,
    int? year,
    String? coverID,
    String? artistID,
    String? artistName,
    List<Track>? songs,
    List<Media>? subsonicSongs,
  }) {
    return AlbumState(
      status: status ?? this.status,
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      coverID: coverID ?? this.coverID,
      artistID: artistID ?? this.artistID,
      artistName: artistName ?? this.artistName,
      songs: songs ?? this.songs,
      subsonicSongs: subsonicSongs ?? this.subsonicSongs,
    );
  }

  @override
  List<Object> get props => [
        status,
        id,
        name,
        year,
        coverID,
        artistID,
        artistName,
        songs,
        subsonicSongs
      ];
}
