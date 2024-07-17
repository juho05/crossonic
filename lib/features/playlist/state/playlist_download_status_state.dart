part of 'playlist_download_status_cubit.dart';

class PlaylistDownloadStatusState extends Equatable {
  final bool waiting;
  final int downloadedSongsCount;
  const PlaylistDownloadStatusState({
    required this.waiting,
    required this.downloadedSongsCount,
  });

  @override
  List<Object> get props => [waiting, downloadedSongsCount];
}
