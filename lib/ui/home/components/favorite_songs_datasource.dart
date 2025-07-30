import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class FavoriteSongsDataSource implements HomeComponentDataSource<Song> {
  final SubsonicRepository _repository;

  FavoriteSongsDataSource({required SubsonicRepository repository})
      : _repository = repository;

  @override
  Future<Result<Iterable<Song>>> get(int count) async {
    final result = await _repository.getStarredSongs();
    switch (result) {
      case Err():
        return Result.error(result.error);
      case Ok():
    }
    return Result.ok(result.value.take(count));
  }
}
