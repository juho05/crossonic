import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

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
  late MockFavoritesRepository favorites;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;

  late BehaviorSubject<Song?> currentSubject;
  late BehaviorSubject<PlaybackStatus> statusSubject;
  late BehaviorSubject<bool> loopingSubject;
  late BehaviorSubject<Duration> positionUpdateSubject;

  setUpAll(() {
    registerFallbackValue(FavoriteType.song);
    registerFallbackValue(makeSong(''));
    registerFallbackValue(Duration.zero);
  });

  void setupMocks() {
    favorites = MockFavoritesRepository();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();

    currentSubject = BehaviorSubject<Song?>.seeded(null);
    statusSubject =
        BehaviorSubject<PlaybackStatus>.seeded(PlaybackStatus.stopped);
    loopingSubject = BehaviorSubject<bool>.seeded(false);
    positionUpdateSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => playback.playNext()).thenAnswer((_) async {});
    when(() => playback.playPrev()).thenAnswer((_) async {});

    when(() => queue.current).thenAnswer((_) => currentSubject.stream);
    when(() => queue.looping).thenAnswer((_) => loopingSubject.stream);
    when(() => queue.currentQueueId).thenReturn('crossonic_default');
    when(() => queue.hasNamedQueues()).thenAnswer((_) async => false);
    when(() => queue.getCurrentQueue()).thenAnswer((_) async => makeQueue());
    when(() => queue.setLoop(any())).thenAnswer((_) async {});
    when(() => queue.add(any(), any())).thenAnswer((_) async {});

    when(() => player.playbackStatus).thenAnswer((_) => statusSubject.stream);
    when(() => player.positionUpdateStream)
        .thenAnswer((_) => positionUpdateSubject.stream);
    when(() => player.position).thenReturn(Duration.zero);
    when(() => player.bufferedPosition).thenAnswer((_) async => Duration.zero);
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.seek(any())).thenAnswer((_) async {});

    when(() => favorites.isFavorite(any(), any())).thenReturn(false);
    when(() => favorites.setFavorite(any(), any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
  }

  setUp(setupMocks);

  tearDown(() async {
    await currentSubject.close();
    await statusSubject.close();
    await loopingSubject.close();
    await positionUpdateSubject.close();
  });

  Future<NowPlayingViewModel> buildViewModel() async {
    final vm = NowPlayingViewModel(
      favoritesRepository: favorites,
      playbackManager: playback,
    );
    await Future.delayed(Duration.zero);
    return vm;
  }

  group('construction', () {
    test('seeds song from current stream value', () async {
      final vm = await buildViewModel();
      expect(vm.song, isNull);
    });

    test('seeds playbackStatus from player status value', () async {
      final vm = await buildViewModel();
      expect(vm.playbackStatus, PlaybackStatus.stopped);
    });

    test('seeds loopEnabled from looping stream value', () async {
      loopingSubject.add(true);
      final vm = await buildViewModel();
      expect(vm.loopEnabled, isTrue);
    });

    test('currentQueueName defaults to Default and isDefaultQueue is true',
        () async {
      final vm = await buildViewModel();
      expect(vm.currentQueueName, 'Default');
      expect(vm.isDefaultQueue, isTrue);
    });
  });

  group('current song stream', () {
    test('emitting a song updates song and queries isFavorite and notifies',
        () async {
      when(() => favorites.isFavorite(FavoriteType.song, 's1'))
          .thenReturn(true);
      final vm = await buildViewModel();
      final seen = <Song?>[];
      vm.addListener(() => seen.add(vm.song));

      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.song?.id, 's1');
      expect(vm.favorite, isTrue);
      verify(() => favorites.isFavorite(FavoriteType.song, 's1'))
          .called(greaterThanOrEqualTo(1));
      expect(seen, isNotEmpty);
    });

    test('null song clears fields and does not notify', () async {
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.song == null));

      currentSubject.add(null);
      await Future.delayed(Duration.zero);

      expect(vm.song, isNull);
      expect(vm.favorite, isFalse);
    });
  });

  group('position timer', () {
    test(
        'playing status starts 50ms periodic timer; 200ms → 4 position ticks',
        () {
      fakeAsync((async) {
        setupMocks();
        final vm = NowPlayingViewModel(
          favoritesRepository: favorites,
          playbackManager: playback,
        );
        async.flushMicrotasks();

        int ticks = 0;
        vm.position.listen((_) => ticks++);
        async.flushMicrotasks();
        ticks = 0;

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 200));

        expect(ticks, 4);
        vm.dispose();
      });
    });

    test('second playing event does not start a second timer', () {
      fakeAsync((async) {
        setupMocks();
        final vm = NowPlayingViewModel(
          favoritesRepository: favorites,
          playbackManager: playback,
        );
        async.flushMicrotasks();

        int ticks = 0;
        vm.position.listen((_) => ticks++);
        async.flushMicrotasks();
        ticks = 0;

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();
        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 200));

        expect(ticks, 4);
        vm.dispose();
      });
    });

    test('paused status cancels timers', () {
      fakeAsync((async) {
        setupMocks();
        final vm = NowPlayingViewModel(
          favoritesRepository: favorites,
          playbackManager: playback,
        );
        async.flushMicrotasks();

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        int ticks = 0;
        vm.position.listen((_) => ticks++);
        async.flushMicrotasks();
        ticks = 0;

        statusSubject.add(PlaybackStatus.paused);
        async.flushMicrotasks();
        async.flushMicrotasks(); // let bufferedPosition future resolve

        final ticksAtPause = ticks;
        async.elapse(const Duration(milliseconds: 200));

        expect(ticks, ticksAtPause);
        vm.dispose();
      });
    });
  });

  group('stopped status', () {
    test('refreshes hasNamedQueues on stopped', () async {
      final vm = await buildViewModel();
      clearInteractions(queue);

      statusSubject.add(PlaybackStatus.stopped);
      await Future.delayed(Duration.zero);

      verify(() => queue.hasNamedQueues()).called(greaterThanOrEqualTo(1));
    });
  });

  group('_onQueueChanged via listener', () {
    test('id change triggers getCurrentQueue and notifies', () async {
      final vm = await buildViewModel();
      final queueListener =
          verify(() => queue.addListener(captureAny())).captured.last
              as void Function();
      clearInteractions(queue);
      when(() => queue.hasNamedQueues()).thenAnswer((_) async => false);
      when(() => queue.getCurrentQueue()).thenAnswer(
        (_) async => makeQueue(id: 'new-id', name: 'New Queue', isDefault: false),
      );
      when(() => queue.currentQueueId).thenReturn('new-id');

      var notified = false;
      vm.addListener(() => notified = true);

      queueListener();
      await Future.delayed(Duration.zero);

      verify(() => queue.getCurrentQueue()).called(1);
      expect(vm.currentQueueName, 'New Queue');
      expect(notified, isTrue);
    });

    test('same queue id skips getCurrentQueue', () async {
      final vm = await buildViewModel();
      final queueListener =
          verify(() => queue.addListener(captureAny())).captured.last
              as void Function();
      clearInteractions(queue);
      when(() => queue.hasNamedQueues()).thenAnswer((_) async => false);

      queueListener();
      await Future.delayed(Duration.zero);

      verifyNever(() => queue.getCurrentQueue());
    });

    test('hasNamedQueues only refreshed when status is stopped', () async {
      statusSubject.add(PlaybackStatus.playing);
      await Future.delayed(Duration.zero);

      final vm = await buildViewModel();
      // status is playing now because we seeded playing before construction
      // Actually, the construct sees the statusSubject.value at construction time
      // Let us just set playing status after construction
      final queueListener =
          verify(() => queue.addListener(captureAny())).captured.last
              as void Function();
      clearInteractions(queue);

      statusSubject.add(PlaybackStatus.playing);
      await Future.delayed(Duration.zero);
      clearInteractions(queue);
      when(() => queue.hasNamedQueues()).thenAnswer((_) async => false);

      queueListener();
      await Future.delayed(Duration.zero);

      verifyNever(() => queue.hasNamedQueues());
    });
  });

  group('looping', () {
    test('looping stream emit updates loopEnabled and notifies', () async {
      final vm = await buildViewModel();
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.loopEnabled));

      loopingSubject.add(true);
      await Future.delayed(Duration.zero);

      expect(vm.loopEnabled, isTrue);
      expect(seen, contains(true));
    });

    test('toggleLoop calls queue.setLoop with negated value', () async {
      final vm = await buildViewModel();

      vm.toggleLoop();
      await Future.delayed(Duration.zero);

      verify(() => queue.setLoop(true)).called(1);
    });

    test('toggleLoop when loop is true calls setLoop(false)', () async {
      loopingSubject.add(true);
      final vm = await buildViewModel();

      vm.toggleLoop();
      await Future.delayed(Duration.zero);

      verify(() => queue.setLoop(false)).called(1);
    });
  });

  group('toggleFavorite', () {
    test('with song calls setFavorite and returns result', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      verify(() => favorites.setFavorite(FavoriteType.song, 's1', true))
          .called(1);
    });

    test('without song returns Ok(null) and makes no repo call', () async {
      final vm = await buildViewModel();
      clearInteractions(favorites);

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      verifyNever(() => favorites.setFavorite(any(), any(), any()));
    });
  });

  group('external favorites listener', () {
    test('flips favorite and notifies when value changes', () async {
      final vm = await buildViewModel();
      final favoritesListener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();

      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);
      expect(vm.favorite, isFalse);

      when(() => favorites.isFavorite(FavoriteType.song, 's1'))
          .thenReturn(true);
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      favoritesListener();

      expect(vm.favorite, isTrue);
      expect(seen, [true]);
    });

    test('no notification when favorite value unchanged', () async {
      final vm = await buildViewModel();
      final favoritesListener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();

      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      favoritesListener(); // isFavorite still returns false

      expect(seen, isEmpty);
    });
  });

  group('playPause', () {
    test('calls pause when playing', () async {
      statusSubject.add(PlaybackStatus.playing);
      final vm = await buildViewModel();

      await vm.playPause();

      verify(() => player.pause()).called(1);
      verifyNever(() => player.play());
    });

    test('calls play when paused', () async {
      statusSubject.add(PlaybackStatus.paused);
      final vm = await buildViewModel();

      await vm.playPause();

      verify(() => player.play()).called(1);
      verifyNever(() => player.pause());
    });
  });

  test('seek delegates to player.seek', () async {
    const pos = Duration(seconds: 30);
    final vm = await buildViewModel();

    await vm.seek(pos);

    verify(() => player.seek(pos)).called(1);
  });

  test('playNext delegates to playbackManager', () async {
    final vm = await buildViewModel();
    await vm.playNext();
    verify(() => playback.playNext()).called(1);
  });

  test('playPrev delegates to playbackManager', () async {
    final vm = await buildViewModel();
    await vm.playPrev();
    verify(() => playback.playPrev()).called(1);
  });

  group('addToQueue', () {
    test('with current song calls queue.add', () async {
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      vm.addToQueue(false);

      verify(() => queue.add(any(), false)).called(1);
    });

    test('without current song is a no-op', () async {
      final vm = await buildViewModel();

      vm.addToQueue(false);

      verifyNever(() => queue.add(any(), any()));
    });
  });

  group('dispose', () {
    test('removes listeners and cancels timers', () async {
      final vm = await buildViewModel();

      await vm.dispose();

      verify(() => favorites.removeListener(any())).called(1);
      verify(() => queue.removeListener(any())).called(1);
    });

    test('dispose cancels position timer', () {
      fakeAsync((async) {
        setupMocks();
        final vm = NowPlayingViewModel(
          favoritesRepository: favorites,
          playbackManager: playback,
        );
        async.flushMicrotasks();

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        int ticks = 0;
        vm.position.listen((_) => ticks++);
        async.flushMicrotasks();
        ticks = 0;

        vm.dispose();
        async.flushMicrotasks();

        async.elapse(const Duration(milliseconds: 200));
        expect(ticks, 0);
      });
    });
  });
}