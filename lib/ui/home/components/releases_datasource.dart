import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class ReleasesDataSource implements HomeComponentDataSource<Album> {
  final SubsonicRepository _repository;
  final AlbumsSortMode _mode;

  ReleasesDataSource({
    required AlbumsSortMode mode,
    required SubsonicRepository repository,
  })  : _repository = repository,
        _mode = mode;

  @override
  Future<Result<Iterable<Album>>> get(int count, {String? seed}) async {
    if (!_repository.supports.randomSeed) seed = null;
    return await _repository.getAlbums(
        _mode, count, 0, _mode == AlbumsSortMode.random ? seed : null);
  }
}
