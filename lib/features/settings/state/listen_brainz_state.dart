part of 'listen_brainz_cubit.dart';

enum ListenBrainzStatus {
  loadingConfig,
  configLoaded,
  configLoadError,
  submitting,
  submitSuccess,
  submitError,
}

class ListenBrainzState extends Equatable {
  final ListenBrainzStatus status;
  final String listenBrainzUsername;
  final String token;
  final String errorText;

  const ListenBrainzState(
      {required this.status,
      this.listenBrainzUsername = "",
      this.token = "",
      this.errorText = ""});

  ListenBrainzState copyWith({
    ListenBrainzStatus? status,
    String? listenBrainzUsername,
    String? token,
    String? errorText,
  }) {
    return ListenBrainzState(
      status: status ?? this.status,
      listenBrainzUsername: listenBrainzUsername ?? this.listenBrainzUsername,
      token: token ?? this.token,
      errorText: errorText ?? this.errorText,
    );
  }

  @override
  List<Object> get props => [status, listenBrainzUsername, token, errorText];
}
