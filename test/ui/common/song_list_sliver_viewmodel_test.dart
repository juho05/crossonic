import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/song_list_sliver_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

Song makeSong(String id) => Song(
      id: id,
      coverId: 'c',
      title: 'T',
      displayArtist: 'A',
      artists: const [],
      album: null,
      genres: const [],
      duration: null,
      bpm: null,
      trackNr: null,
      discNr: null,
      trackGain: null,
      albumGain: null,
      fallbackGain: null,
      originalDate: null,
      releaseDate: null,
      contentType: null,
      sampleRate: null,
      bitDepth: null,
      bitRate: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const <Song>[]);
  });

  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;

  setUp(() {
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => queue.replace(any(), any())).thenAnswer((_) async {});
  });

  SongListSliverViewModel buildViewModel() =>
      SongListSliverViewModel(playbackManager: playback);

  group('play', () {
    test('play(songs, index, single:false) calls playOnNextMediaChange and queue.replace(songs, index)', () async {
      final songs = [makeSong('a'), makeSong('b'), makeSong('c')];
      final vm = buildViewModel();

      await vm.play(songs, 1, false);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 1)).called(1);
    });

    test('play(songs, index, single:true) replaces queue with only the selected song at index 0', () async {
      final songs = [makeSong('a'), makeSong('b'), makeSong('c')];
      final vm = buildViewModel();

      when(() => queue.replace(any())).thenAnswer((_) async {});

      await vm.play(songs, 2, true);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace([songs[2]])).called(1);
    });
  });
}