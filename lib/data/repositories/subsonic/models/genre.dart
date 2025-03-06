import 'package:crossonic/data/services/opensubsonic/models/genre_model.dart';

class Genre {
  final String name;
  final int songCount;
  final int albumCount;

  Genre({
    required this.name,
    required this.songCount,
    required this.albumCount,
  });

  factory Genre.fromGenreModel(GenreModel g) {
    return Genre(
      name: g.value,
      albumCount: g.albumCount,
      songCount: g.songCount,
    );
  }
}
