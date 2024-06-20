part of 'create_playlist_cubit.dart';

enum CreatePlaylistStatus {
  initial,
  none,
  loading,
  created,
  connectionError,
  unexpectedError
}

class CreatePlaylistState extends Equatable {
  final CreatePlaylistStatus status;
  final String name;
  const CreatePlaylistState({
    required this.status,
    required this.name,
  });

  CreatePlaylistState copyWith({
    CreatePlaylistStatus? status,
    String? name,
  }) {
    return CreatePlaylistState(
      status: status ?? this.status,
      name: name ?? this.name,
    );
  }

  @override
  List<Object> get props => [status, name];
}
