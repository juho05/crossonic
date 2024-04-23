part of 'recently_added_albums_cubit.dart';

class RecentlyAddedAlbum extends Equatable {
  final String name;
  final String artist;
  final String? coverURL;

  const RecentlyAddedAlbum({
    required this.name,
    required this.artist,
    required this.coverURL,
  });

  @override
  List<Object?> get props => [name, artist, coverURL];
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
