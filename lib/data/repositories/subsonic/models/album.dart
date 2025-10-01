import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';

enum ReleaseType { live, remix, demo, compilation, single, ep, album }

class Album {
  final String id;
  final String name;
  final String coverId;
  final List<Song>? songs;
  final int songCount;
  final String displayArtist;
  final Iterable<({String id, String name})> artists;
  final Map<int, String> discTitles;
  final ReleaseType releaseType;
  final Date? releaseDate;
  final Date? originalDate;
  final String? version;
  final String? musicBrainzId;

  Album({
    required this.id,
    required this.name,
    required this.coverId,
    required this.releaseDate,
    required this.originalDate,
    required this.songs,
    required this.songCount,
    required this.displayArtist,
    required this.artists,
    required this.discTitles,
    required this.releaseType,
    required this.version,
    required this.musicBrainzId,
  });

  factory Album.fromAlbumID3Model(AlbumID3Model album) {
    ReleaseType releaseType = ReleaseType.album;
    for (String type in album.releaseTypes ?? []) {
      type = type.toLowerCase().trim();
      final t = ReleaseType.values
          .firstWhere((t) => t.name == type, orElse: () => ReleaseType.album);
      if (t.index < releaseType.index) {
        releaseType = t;
      }
    }

    Date? originalDate;
    if (album.originalReleaseDate != null &&
        album.originalReleaseDate!.year != null) {
      originalDate = Date.fromItemDateModel(album.originalReleaseDate!);
    } else if (album.year != null) {
      originalDate = Date(year: album.year!, month: null, day: null);
    }

    Date? releaseDate;
    if (album.releaseDate != null && album.releaseDate!.year != null) {
      releaseDate = Date.fromItemDateModel(album.releaseDate!);
    } else if (album.year != null) {
      releaseDate = Date(year: album.year!, month: null, day: null);
    }

    if (releaseDate != null) {
      if (originalDate != null) {
        if (originalDate > releaseDate) {
          releaseDate = originalDate;
        }
      } else {
        originalDate = releaseDate;
      }
    }

    return Album(
      id: album.id,
      name: album.name,
      coverId: album.coverArt ?? album.id,
      displayArtist: album.displayArtist ??
          album.artists?.map((a) => a.name).join(", ") ??
          album.artist ??
          "Unknown artist",
      artists: album.artists ??
          (album.artist != null && album.artistId != null
              ? [(id: album.artistId!, name: album.artist!)]
              : []),
      originalDate: originalDate,
      releaseDate: releaseDate,
      songs: album.song?.map((c) => Song.fromChildModel(c)).toList(),
      songCount: album.songCount,
      discTitles: {
        for (var d in album.discTitles ?? <({int disc, String title})>[])
          d.disc: d.title
      },
      releaseType: releaseType,
      version: album.version,
      musicBrainzId: album.musicBrainzId,
    );
  }
}
