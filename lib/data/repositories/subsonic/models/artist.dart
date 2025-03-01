import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';

class Artist {
  final String id;
  final String name;
  final String coverId;
  final List<Album>? albums;
  final int? albumCount;
  final List<String>? genres;

  Artist({
    required this.id,
    required this.name,
    required this.coverId,
    required this.albums,
    required this.albumCount,
    required this.genres,
  });

  factory Artist.fromArtistID3Model(ArtistID3Model a) {
    return Artist(
        id: a.id,
        name: a.name,
        albums: a.album?.map((a) => Album.fromAlbumID3Model(a)).toList(),
        albumCount: a.albumCount,
        coverId: a.coverArt ?? a.id,
        genres: a.album
            ?.expand((a) =>
                a.genres?.map((g) => g.name).toList() ??
                (a.genre != null ? [a.genre!] : <String>[]))
            .toList());
  }
}
