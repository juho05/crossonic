import 'package:collection/collection.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class RandomArtistsDataSource implements HomeComponentDataSource<Artist> {
  final SubsonicRepository _repository;

  RandomArtistsDataSource({
    required SubsonicRepository repository,
  }) : _repository = repository;

  @override
  Future<Result<Iterable<Artist>>> get(int count) async {
    final result = await _repository.getArtists();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.shuffled().take(count));
  }
}
