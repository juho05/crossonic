part of 'albums_bloc.dart';

sealed class AlbumsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class AlbumSortModeSelected extends AlbumsEvent {
  final AlbumSortMode mode;
  AlbumSortModeSelected(this.mode);
}

final class AlbumsNextPageFetched extends AlbumsEvent {}
