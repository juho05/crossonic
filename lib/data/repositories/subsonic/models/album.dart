import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';

class Album {
  final String id;
  final String name;
  final String coverId;
  final int? year;
  final List<Song> songs;
  final String displayArtist;
  final Iterable<({String id, String name})> artists;

  Album({
    required this.id,
    required this.name,
    required this.coverId,
    required this.year,
    required this.songs,
    required this.displayArtist,
    required this.artists,
  });

  factory Album.fromAlbumID3Model(AlbumID3Model album) {
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
      year: album.year,
      songs: album.song.map((c) => Song.fromChildModel(c)).toList(),
    );
  }
}
