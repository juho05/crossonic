part of 'lyrics_cubit.dart';

class LyricsState extends Equatable {
  final FetchStatus status;
  final Iterable<String> lines;
  final bool noSong;
  const LyricsState({
    required this.status,
    required this.lines,
    this.noSong = false,
  });

  LyricsState copyWith({
    FetchStatus? status,
    Iterable<String>? lines,
    bool? noSong,
  }) {
    return LyricsState(
      status: status ?? this.status,
      lines: lines ?? this.lines,
      noSong: noSong ?? this.noSong,
    );
  }

  @override
  List<Object> get props => [status, lines, noSong];
}
