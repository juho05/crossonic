import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class FavoriteArtistsDataSource implements HomeComponentDataSource<Artist> {
  final SubsonicRepository _repository;

  FavoriteArtistsDataSource({
    required SubsonicRepository repository,
  }) : _repository = repository;

  @override
  Future<Result<Iterable<Artist>>> get(int count, {String? seed}) async {
    final result = await _repository.getStarredArtists();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.take(count));
  }
}
