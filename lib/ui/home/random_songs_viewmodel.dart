import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/result.dart';

class RandomSongsViewModel {
  final SubsonicRepository _subsonicRepository;

  late final Command0<List<Song>> load;

  RandomSongsViewModel({
    required SubsonicRepository subsonicRepository,
  }) : _subsonicRepository = subsonicRepository {
    load = Command0(_load);
    load.execute();
  }

  Future<Result<List<Song>>> _load() async {
    return await _subsonicRepository.getRandomSongs(count: 10);
  }
}
