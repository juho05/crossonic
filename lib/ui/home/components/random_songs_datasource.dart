import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class RandomSongsDataSource implements HomeComponentDataSource<Song> {
  final SubsonicRepository _repository;

  RandomSongsDataSource({required SubsonicRepository repository})
      : _repository = repository;

  @override
  Future<Result<Iterable<Song>>> get(int count) async {
    return await _repository.getRandomSongs(count: count);
  }
}
