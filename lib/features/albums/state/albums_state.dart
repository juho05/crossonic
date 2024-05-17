part of 'albums_bloc.dart';

class AlbumListItem extends Equatable {
  final String id;
  final String name;
  final Artists artists;
  final String? coverID;
  final int? year;

  const AlbumListItem({
    required this.id,
    required this.name,
    required this.artists,
    required this.coverID,
    this.year,
  });

  @override
  List<Object?> get props => [id, name, artists, coverID, year];
}

class AlbumsState extends Equatable {
  const AlbumsState({
    this.status = FetchStatus.initial,
    this.albums = const [],
    this.reachedEnd = false,
    this.sortMode = AlbumSortMode.random,
  });

  final FetchStatus status;
  final List<AlbumListItem> albums;
  final bool reachedEnd;
  final AlbumSortMode sortMode;

  AlbumsState copyWith({
    FetchStatus? status,
    List<AlbumListItem>? albums,
    bool? reachedEnd,
    AlbumSortMode? sortMode,
  }) {
    return AlbumsState(
      status: status ?? this.status,
      albums: albums ?? this.albums,
      reachedEnd: reachedEnd ?? this.reachedEnd,
      sortMode: sortMode ?? this.sortMode,
    );
  }

  @override
  List<Object> get props => [status, albums, reachedEnd];
}
