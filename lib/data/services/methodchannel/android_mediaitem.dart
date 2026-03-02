import 'dart:typed_data';

enum AndroidLibraryContentStyle { list, grid }

class AndroidMediaItem {
  final String id;
  final bool browsable;
  final bool playable;

  final String? uri;
  final String? title;
  final String? album;
  final String? artist;
  final int? discNumber;
  final int? durationMs;
  final String? genre;
  final int? trackNumber;
  final int? releaseYear;
  final int? releaseMonth;
  final int? releaseDay;
  final Uint8List? artworkData;
  final Uri? artworkContentUri;
  final AndroidLibraryContentStyle? contentStyle;

  AndroidMediaItem({
    required this.id,
    required this.browsable,
    required this.playable,
    this.uri,
    this.title,
    this.album,
    this.artist,
    this.discNumber,
    this.durationMs,
    this.genre,
    this.trackNumber,
    this.releaseYear,
    this.releaseMonth,
    this.releaseDay,
    this.artworkData,
    this.artworkContentUri,
    this.contentStyle,
  });

  Map<String, dynamic> toMsgData() {
    return {
      "id": id,
      "browsable": browsable,
      "playable": playable,
      if (uri != null) "uri": uri,
      if (title != null) "title": title,
      if (album != null) "album": album,
      if (artist != null) "artist": artist,
      if (discNumber != null) "discNumber": discNumber,
      if (durationMs != null) "durationMs": durationMs,
      if (genre != null) "genre": genre,
      if (trackNumber != null) "trackNumber": trackNumber,
      if (releaseYear != null) "releaseYear": releaseYear,
      if (releaseMonth != null) "releaseMonth": releaseMonth,
      if (releaseDay != null) "releaseDay": releaseDay,
      if (artworkData != null) "artworkData": artworkData,
      if (artworkContentUri != null)
        "artworkContentUri": artworkContentUri.toString(),
      if (contentStyle != null) "contentStyle": contentStyle!.name,
    };
  }
}
