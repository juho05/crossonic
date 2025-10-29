import 'dart:math';

import 'package:collection/collection.dart';
import 'package:crossonic/data/services/opensubsonic/models/lyrics_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/structured_lyrics_model.dart';

class Lyrics {
  final List<LyricsLine> lines;
  final bool synced;

  Lyrics({required this.lines, required this.synced});

  factory Lyrics.fromStructuredLyrics(StructuredLyricsModel lyrics) {
    final offset = (lyrics.offset ?? 0).round();
    final firstLine = lyrics.line!.firstOrNull;
    final needsEmptyStartLine =
        firstLine != null &&
        firstLine.value.isNotEmpty &&
        (firstLine.start?.round() ?? 0) - offset > 1000;
    return Lyrics(
      synced: lyrics.synced,
      lines:
          [if (needsEmptyStartLine) LyricsLine(text: "", start: Duration.zero)]
              .followedBy(
                lyrics.line!.mapIndexed((index, element) {
                  final start = !needsEmptyStartLine && index == 0
                      ? Duration.zero
                      : (element.start != null
                            ? Duration(
                                milliseconds: max(
                                  element.start!.round() - offset,
                                  0,
                                ),
                              )
                            : null);
                  return LyricsLine(text: element.value.trim(), start: start);
                }),
              )
              .toList(),
    );
  }

  factory Lyrics.fromLyricsModel(LyricsModel model) {
    return Lyrics(
      lines: model.value
          .split("\n")
          .map((e) => LyricsLine(text: e.trim()))
          .toList(),
      synced: false,
    );
  }
}

class LyricsLine {
  final String text;
  final Duration? start;

  LyricsLine({required this.text, this.start});
}
