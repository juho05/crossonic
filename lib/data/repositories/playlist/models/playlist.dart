class Playlist {
  final String id;
  final String name;
  final String? comment;
  final int songCount;
  final Duration duration;
  final DateTime created;
  final DateTime changed;
  final String? coverId;
  final bool download;

  Playlist({
    required this.id,
    required this.name,
    required this.comment,
    required this.songCount,
    required this.duration,
    required this.created,
    required this.changed,
    required this.coverId,
    required this.download,
  });
}
