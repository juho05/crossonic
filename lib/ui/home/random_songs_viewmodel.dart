import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/utils/command.dart';
import 'package:crossonic/utils/result.dart';

class RandomSongsViewModel {
  final SubsonicRepository _subsonicRepository;
  final AudioHandler _audioHandler;

  late final Command0<List<Song>> load;

  RandomSongsViewModel({
    required SubsonicRepository subsonicRepository,
    required AudioHandler audioHandler,
  })  : _subsonicRepository = subsonicRepository,
        _audioHandler = audioHandler {
    load = Command0(_load);
    load.execute();
  }

  Future<Result<List<Song>>> _load() async {
    return await _subsonicRepository.getRandomSongs(count: 10);
  }

  Future<void> play(int songIndex) async {
    if (!load.completed) return;
    _audioHandler.playOnNextMediaChange();
    _audioHandler.replace(load.result!.tryValue!, songIndex);
  }

  void addSongToQueue(Song song, bool priority) {
    _audioHandler.add(song, priority);
  }
}
