part of 'recently_added_albums_cubit.dart';

class RecentlyAddedAlbum extends Equatable {
  final String id;
  final String name;
  final Artists artists;
  final String? coverID;
  final int? year;

  const RecentlyAddedAlbum({
    required this.id,
    required this.name,
    required this.artists,
    required this.coverID,
    this.year,
  });

  @override
  List<Object?> get props => [id, name, artists, coverID, year];
}

class RecentlyAddedAlbumsState extends Equatable {
  const RecentlyAddedAlbumsState({
    this.status = FetchStatus.initial,
    this.albums = const [],
    this.reachedEnd = false,
  });

  final FetchStatus status;
  final List<RecentlyAddedAlbum> albums;
  final bool reachedEnd;

  RecentlyAddedAlbumsState copyWith({
    FetchStatus? status,
    List<RecentlyAddedAlbum>? albums,
    bool? reachedEnd,
  }) {
    return RecentlyAddedAlbumsState(
      status: status ?? this.status,
      albums: albums ?? this.albums,
      reachedEnd: reachedEnd ?? this.reachedEnd,
    );
  }

  @override
  List<Object> get props => [status, albums, reachedEnd];
}
