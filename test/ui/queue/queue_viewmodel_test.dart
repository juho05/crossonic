import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/players/local_song_source.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/prefetch/queue_prefetcher.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/queue/queue_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

class MockCompositeLocalSource extends Mock implements CompositeLocalSource {}

class MockQueuePrefetcher extends Mock implements QueuePrefetcher {}

Song makeSong(String id) => Song(
      id: id,
      coverId: 'cover-$id',
      title: 'Song $id',
      displayArtist: 'Artist',
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

Queue makeQueue({
  String id = 'crossonic_default',
  String name = 'Default',
  bool isDefault = true,
}) =>
    Queue(
      id: id,
      name: name,
      songCount: 0,
      currentIndex: 0,
      isDefault: isDefault,
    );

void main() {
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;
  late MockCompositeLocalSource localSource;
  late MockQueuePrefetcher prefetcher;
  late BehaviorSubject<Song?> current;
  late BehaviorSubject<String?> currentDownload;

  setUp(() {
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();
    localSource = MockCompositeLocalSource();
    prefetcher = MockQueuePrefetcher();
    current = BehaviorSubject<Song?>.seeded(null);
    currentDownload = BehaviorSubject<String?>.seeded(null);

    when(() => playback.queue).thenReturn(queue);
    when(() => playback.player).thenReturn(player);
    when(() => player.playOnNextMediaChange()).thenReturn(null);

    when(() => queue.current).thenAnswer((_) => current.stream);
    when(() => prefetcher.currentDownloadSongId)
        .thenAnswer((_) => currentDownload.stream);

    when(() => queue.length).thenReturn(0);
    when(() => queue.currentIndex).thenReturn(-1);
    when(() => queue.priorityLength).thenReturn(0);
    when(() => queue.currentQueueId).thenReturn('crossonic_default');
    when(() => queue.getCurrentQueue())
        .thenAnswer((_) async => makeQueue());
    when(() => queue.getRegularSongs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => const []);
    when(() => queue.getPrioritySongs(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => const []);

    when(() => queue.clear(
          queue: any(named: 'queue'),
          fromIndex: any(named: 'fromIndex'),
          priorityQueue: any(named: 'priorityQueue'),
        )).thenAnswer((_) async {});
    when(() => queue.shuffleFollowing()).thenAnswer((_) async {});
    when(() => queue.shufflePriority()).thenAnswer((_) async {});
    when(() => queue.remove(any())).thenAnswer((_) async {});
    when(() => queue.removeFromPriorityQueue(any())).thenAnswer((_) async {});
    when(() => queue.goTo(any())).thenAnswer((_) async {});
    when(() => queue.goToPriority(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await current.close();
    await currentDownload.close();
  });

  Future<QueueViewModel> buildViewModel() async {
    final vm = QueueViewModel(
      playbackManager: playback,
      compositeLocalSource: localSource,
      queuePrefetcher: prefetcher,
    );
    // Let the initial _queueChanged()/_currentChanged() futures settle.
    await Future.delayed(Duration.zero);
    return vm;
  }

  group('queue lengths', () {
    test('regular length excludes the current song and everything before it',
        () async {
      when(() => queue.length).thenReturn(10);
      when(() => queue.currentIndex).thenReturn(3);
      when(() => queue.priorityLength).thenReturn(2);

      final vm = await buildViewModel();

      expect(vm.queueLength, 6);
      expect(vm.prioQueueLength, 2);
    });

    test('regular length is clamped to zero', () async {
      when(() => queue.length).thenReturn(2);
      when(() => queue.currentIndex).thenReturn(3);

      final vm = await buildViewModel();

      expect(vm.queueLength, 0);
    });
  });

  group('current queue metadata', () {
    test('exposes the name and default flag of the active queue', () async {
      when(() => queue.currentQueueId).thenReturn('custom');
      when(() => queue.getCurrentQueue()).thenAnswer(
        (_) async => makeQueue(id: 'custom', name: 'Roadtrip', isDefault: false),
      );

      final vm = await buildViewModel();

      expect(vm.currentQueueName, 'Roadtrip');
      expect(vm.isDefaultQueue, isFalse);
    });
  });

  group('index mapping', () {
    // prioQueueLength = 2 (indices 0,1), the current song sits at index 2,
    // the regular "up next" queue starts at index 3 and maps onto
    // currentIndex (3) + 1 = 4 in the underlying queue.
    setUp(() {
      when(() => queue.length).thenReturn(10);
      when(() => queue.currentIndex).thenReturn(3);
      when(() => queue.priorityLength).thenReturn(2);
    });

    test('remove routes the first priority index to the priority queue',
        () async {
      final vm = await buildViewModel();

      await vm.remove(0);

      verify(() => queue.removeFromPriorityQueue(0)).called(1);
      verifyNever(() => queue.remove(any()));
    });

    test('remove routes the last priority index to the priority queue',
        () async {
      final vm = await buildViewModel();

      await vm.remove(1);

      verify(() => queue.removeFromPriorityQueue(1)).called(1);
      verifyNever(() => queue.remove(any()));
    });

    test('remove maps the first regular index onto the song after current',
        () async {
      final vm = await buildViewModel();

      await vm.remove(3);

      verify(() => queue.remove(4)).called(1);
      verifyNever(() => queue.removeFromPriorityQueue(any()));
    });

    test('remove translates a later regular index', () async {
      final vm = await buildViewModel();

      await vm.remove(5);

      // index 5 -> drop priority(2)+current(1) -> currentIndex+offset+1 = 6
      verify(() => queue.remove(6)).called(1);
      verifyNever(() => queue.removeFromPriorityQueue(any()));
    });

    test('goto arms play-on-change and routes the first priority index',
        () async {
      final vm = await buildViewModel();

      await vm.goto(0);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.goToPriority(0)).called(1);
    });

    test('goto routes the last priority index', () async {
      final vm = await buildViewModel();

      await vm.goto(1);

      verify(() => queue.goToPriority(1)).called(1);
      verifyNever(() => queue.goTo(any()));
    });

    test('goto maps the first regular index onto the song after current',
        () async {
      final vm = await buildViewModel();

      await vm.goto(3);

      verify(() => queue.goTo(4)).called(1);
      verifyNever(() => queue.goToPriority(any()));
    });

    test('goto translates a later regular index', () async {
      final vm = await buildViewModel();

      await vm.goto(5);

      verify(() => queue.goTo(6)).called(1);
    });

    test('getSong returns null for out-of-range indices', () async {
      final vm = await buildViewModel();

      expect(vm.getSong(-1), isNull);
      expect(vm.getSong(vm.queueLength), isNull);
    });

    test('getPrioSong returns null for out-of-range indices', () async {
      final vm = await buildViewModel();

      expect(vm.getPrioSong(-1), isNull);
      expect(vm.getPrioSong(vm.prioQueueLength), isNull);
    });
  });

  group('bulk queue actions', () {
    test('clearQueue removes everything after the current song', () async {
      when(() => queue.currentIndex).thenReturn(3);
      final vm = await buildViewModel();

      await vm.clearQueue();

      verify(() => queue.clear(priorityQueue: false, fromIndex: 4)).called(1);
    });

    test('clearPriorityQueue only clears the priority queue', () async {
      final vm = await buildViewModel();

      await vm.clearPriorityQueue();

      verify(() => queue.clear(queue: false)).called(1);
    });

    test('shuffle actions delegate to the queue manager', () async {
      final vm = await buildViewModel();

      await vm.shuffleQueue();
      await vm.shufflePriorityQueue();

      verify(() => queue.shuffleFollowing()).called(1);
      verify(() => queue.shufflePriority()).called(1);
    });
  });

  group('notifications', () {
    test('updates the current song and notifies when the stream emits',
        () async {
      final vm = await buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      current.add(makeSong('now-playing'));
      await Future.delayed(Duration.zero);

      expect(vm.currentSong?.id, 'now-playing');
      expect(notified, isTrue);
    });

    test('notifies when the active download changes', () async {
      when(() => localSource.isDownloaded(any())).thenReturn(false);
      final vm = await buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      currentDownload.add('downloading-now');
      await Future.delayed(Duration.zero);

      expect(notified, isTrue);
      expect(vm.getDownloadStatus('downloading-now'),
          DownloadStatus.downloading);
    });

    test('notifies when the queue manager reports a change', () async {
      final vm = await buildViewModel();
      final queueListener =
          verify(() => queue.addListener(captureAny())).captured.last
              as void Function();
      var notified = false;
      vm.addListener(() => notified = true);

      queueListener();
      await Future.delayed(Duration.zero);

      expect(notified, isTrue);
    });
  });

  group('getDownloadStatus', () {
    test('reports downloaded songs', () async {
      when(() => localSource.isDownloaded('s1')).thenReturn(true);
      final vm = await buildViewModel();

      expect(vm.getDownloadStatus('s1'), DownloadStatus.downloaded);
    });

    test('reports the actively downloading song', () async {
      when(() => localSource.isDownloaded(any())).thenReturn(false);
      currentDownload.add('s2');
      await Future.delayed(Duration.zero);
      final vm = await buildViewModel();

      expect(vm.getDownloadStatus('s2'), DownloadStatus.downloading);
      expect(vm.getDownloadStatus('s3'), DownloadStatus.none);
    });
  });
}
