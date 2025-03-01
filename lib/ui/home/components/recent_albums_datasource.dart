import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/utils/result.dart';

class RecentlyAddedAlbumsDataSource implements HomeComponentDataSource<Album> {
  final SubsonicRepository _repository;

  RecentlyAddedAlbumsDataSource({required SubsonicRepository repository})
      : _repository = repository;

  @override
  Future<Result<Iterable<Album>>> get(int count) async {
    return await _repository.getAlbums(AlbumsSortMode.recentlyAdded, count);
  }
}
