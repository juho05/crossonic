class Lyrics {
  final List<LyricsLine> lines;
  final bool synced;

  Lyrics({required this.lines, required this.synced});
}

class LyricsLine {
  final String text;
  final Duration? start;
  final Duration? end;

  LyricsLine({required this.text, this.start, this.end});
}
