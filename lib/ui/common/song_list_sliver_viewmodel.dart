import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';

class SongListSliverViewModel {
  final AudioHandler _audioHandler;
  SongListSliverViewModel({required AudioHandler audioHandler})
      : _audioHandler = audioHandler;

  Future<void> play(List<Song> songs, int songIndex, bool single) async {
    _audioHandler.playOnNextMediaChange();
    if (single) {
      _audioHandler.queue.replace([songs[songIndex]]);
    } else {
      _audioHandler.queue.replace(songs, songIndex);
    }
  }
}
