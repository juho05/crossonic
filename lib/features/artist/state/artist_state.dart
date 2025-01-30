part of 'artist_cubit.dart';

class Track extends Equatable {
  final String id;
  final String title;
  final Duration duration;

  const Track({
    required this.id,
    required this.title,
    required this.duration,
  });

  @override
  List<Object?> get props => [id, title, duration];
}

class ArtistAlbum extends Equatable {
  final String id;
  final String name;
  final String? coverID;
  final int? year;
  final List<ArtistIDName> artists;

  const ArtistAlbum({
    required this.id,
    required this.name,
    required this.coverID,
    required this.artists,
    this.year,
  });

  @override
  List<Object?> get props => [id, name, coverID, year, artists];
}

class ArtistState extends Equatable {
  const ArtistState({
    required this.status,
    required this.id,
    required this.name,
    required this.albumCount,
    required this.coverID,
    required this.albums,
    required this.genres,
    required this.description,
  });

  final FetchStatus status;
  final String id;
  final String name;
  final int albumCount;
  final String coverID;
  final List<ArtistAlbum> albums;
  final List<String> genres;
  final String description;

  ArtistState copyWith({
    FetchStatus? status,
    String? id,
    String? name,
    int? albumCount,
    String? coverID,
    List<ArtistAlbum>? albums,
    List<String>? genres,
    String? description,
  }) {
    return ArtistState(
      status: status ?? this.status,
      id: id ?? this.id,
      name: name ?? this.name,
      albumCount: albumCount ?? this.albumCount,
      coverID: coverID ?? this.coverID,
      albums: albums ?? this.albums,
      genres: genres ?? this.genres,
      description: description ?? this.description,
    );
  }

  @override
  List<Object> get props => [
        status,
        id,
        name,
        albumCount,
        coverID,
        albums,
        genres,
        description,
      ];
}
