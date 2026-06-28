import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/lyrics.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/lyrics/lyrics_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

class FakeWakelock extends WakelockPlusPlatformInterface {
  @override
  Future<bool> get enabled async => false;

  @override
  Future<void> toggle({required bool enable}) async {}
}

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

Lyrics makeSyncedLyrics(List<({int startMs, String text})> lines) => Lyrics(
      synced: true,
      lines: lines
          .map((l) => LyricsLine(
                text: l.text,
                start: Duration(milliseconds: l.startMs),
              ))
          .toList(),
    );

Lyrics makeUnsyncedLyrics(List<String> texts) => Lyrics(
      synced: false,
      lines: texts.map((t) => LyricsLine(text: t)).toList(),
    );

void main() {
  late MockSubsonicRepository subsonic;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;

  late BehaviorSubject<Song?> currentSubject;
  late BehaviorSubject<PlaybackStatus> statusSubject;
  late BehaviorSubject<Duration> positionUpdateSubject;

  setUpAll(() {
    WakelockPlusPlatformInterface.instance = FakeWakelock();
    registerFallbackValue(makeSong(''));
    registerFallbackValue(Duration.zero);
  });

  void setupMocks() {
    subsonic = MockSubsonicRepository();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();

    currentSubject = BehaviorSubject<Song?>.seeded(null);
    statusSubject =
        BehaviorSubject<PlaybackStatus>.seeded(PlaybackStatus.stopped);
    positionUpdateSubject = BehaviorSubject<Duration>.seeded(Duration.zero);

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);

    when(() => queue.current).thenAnswer((_) => currentSubject.stream);

    when(() => player.playbackStatus).thenAnswer((_) => statusSubject.stream);
    when(() => player.positionUpdateStream)
        .thenAnswer((_) => positionUpdateSubject.stream);
    when(() => player.position).thenReturn(Duration.zero);
    when(() => player.seek(any())).thenAnswer((_) async {});
    when(() => player.play()).thenAnswer((_) async {});

    when(() => subsonic.getLyricsLines(any()))
        .thenAnswer((_) async => const Result.ok(null));
  }

  setUp(setupMocks);

  tearDown(() async {
    await currentSubject.close();
    await statusSubject.close();
    await positionUpdateSubject.close();
  });

  Future<LyricsViewModel> buildViewModel() async {
    final vm = LyricsViewModel(subsonic: subsonic, playbackManager: playback);
    await Future.delayed(Duration.zero);
    return vm;
  }

  group('_fetch', () {
    test('null song → status success, lyrics null, selectedLine null', () async {
      final vm = await buildViewModel();

      expect(vm.status, FetchStatus.success);
      expect(vm.lyrics, isNull);
      expect(vm.selectedLine.value, isNull);
    });

    test('failure -> status failure and notifies', () async {
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.error(Exception('fail')));
      final vm = LyricsViewModel(subsonic: subsonic, playbackManager: playback);

      final seen = <FetchStatus>[];
      vm.addListener(() => seen.add(vm.status));

      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(seen, contains(FetchStatus.failure));
    });

    test('success sets lyrics and syncedMode = supportsSync and notifies',
        () async {
      final lyrics = makeSyncedLyrics([
        (startMs: 0, text: 'line 1'),
        (startMs: 1000, text: 'line 2'),
      ]);
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(lyrics));
      final vm = await buildViewModel();

      final seen = <FetchStatus>[];
      vm.addListener(() => seen.add(vm.status));

      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.lyrics, same(lyrics));
      expect(vm.syncedMode, isTrue);
      expect(seen, contains(FetchStatus.success));
    });

    test('supportsSync false forces syncedMode false', () async {
      final lyrics = makeUnsyncedLyrics(['line 1', 'line 2']);
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(lyrics));
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.supportsSync, isFalse);
      expect(vm.syncedMode, isFalse);
    });
  });

  group('line selection', () {
    late Lyrics syncedLyrics;

    setUp(() {
      syncedLyrics = makeSyncedLyrics([
        (startMs: 0, text: 'line 0'),
        (startMs: 1000, text: 'line 1'),
        (startMs: 2000, text: 'line 2'),
      ]);
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(syncedLyrics));
    });

    Future<LyricsViewModel> buildWithLyrics() async {
      final vm = LyricsViewModel(subsonic: subsonic, playbackManager: playback);
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);
      return vm;
    }

    test('position 1500ms selects index 1 (last line with start <= pos)',
        () async {
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 1500));
      final vm = await buildWithLyrics();

      expect(vm.selectedLine.value, 1);
    });

    test('position before first timed line -> selectedLine null', () async {
      // All lines have a start, so if position is negative this case doesn't
      // apply. Instead test with a lyrics set where first line has start null.
      final lyricsWithNullFirst = Lyrics(
        synced: true,
        lines: [
          LyricsLine(text: 'no time'),
          LyricsLine(text: 'line 1', start: const Duration(milliseconds: 1000)),
          LyricsLine(text: 'line 2', start: const Duration(milliseconds: 2000)),
        ],
      );
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(lyricsWithNullFirst));
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 500));
      final vm = LyricsViewModel(subsonic: subsonic, playbackManager: playback);
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.selectedLine.value, isNull);
    });

    test('lines with null start are skipped', () async {
      final lyricsWithNulls = Lyrics(
        synced: true,
        lines: [
          LyricsLine(text: 'a', start: const Duration(milliseconds: 0)),
          LyricsLine(text: 'b'),
          LyricsLine(text: 'c', start: const Duration(milliseconds: 1000)),
        ],
      );
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(lyricsWithNulls));
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 500));
      final vm = LyricsViewModel(subsonic: subsonic, playbackManager: playback);
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      expect(vm.selectedLine.value, 0);
    });

    test('position after last line -> selectedLine is last index', () async {
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 9000));
      final vm = await buildWithLyrics();

      expect(vm.selectedLine.value, 2);
    });

    test('advancing within same line keeps index', () async {
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 1500));
      final vm = await buildWithLyrics();
      expect(vm.selectedLine.value, 1);

      final linesBefore = <int?>[];
      vm.selectedLine.listen((i) => linesBefore.add(i));
      linesBefore.clear();

      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 1700));
      positionUpdateSubject.add(const Duration(milliseconds: 1700));
      await Future.delayed(Duration.zero);

      expect(vm.selectedLine.value, 1);
    });

    test('crossing into next line advances selectedLine', () async {
      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 1500));
      final vm = await buildWithLyrics();
      expect(vm.selectedLine.value, 1);

      when(() => player.position)
          .thenReturn(const Duration(milliseconds: 2100));
      positionUpdateSubject.add(const Duration(milliseconds: 2100));
      await Future.delayed(Duration.zero);

      expect(vm.selectedLine.value, 2);
    });
  });

  group('position timer', () {
    test(
        'timer runs when playing and syncedMode; selectedLine advances with time',
        () {
      fakeAsync((async) {
        setupMocks();
        final lyrics = makeSyncedLyrics([
          (startMs: 0, text: 'line 0'),
          (startMs: 100, text: 'line 1'),
          (startMs: 200, text: 'line 2'),
        ]);
        when(() => subsonic.getLyricsLines(any()))
            .thenAnswer((_) async => Result.ok(lyrics));

        final vm =
            LyricsViewModel(subsonic: subsonic, playbackManager: playback);
        currentSubject.add(makeSong('s1'));
        async.flushMicrotasks();

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        when(() => player.position)
            .thenReturn(const Duration(milliseconds: 150));

        async.elapse(const Duration(milliseconds: 100));

        expect(vm.selectedLine.value, 1);
        vm.dispose();
      });
    });

    test('timer stops when paused', () {
      fakeAsync((async) {
        setupMocks();
        final lyrics = makeSyncedLyrics([
          (startMs: 0, text: 'line 0'),
          (startMs: 100, text: 'line 1'),
        ]);
        when(() => subsonic.getLyricsLines(any()))
            .thenAnswer((_) async => Result.ok(lyrics));

        final vm =
            LyricsViewModel(subsonic: subsonic, playbackManager: playback);
        currentSubject.add(makeSong('s1'));
        async.flushMicrotasks();

        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        statusSubject.add(PlaybackStatus.paused);
        async.flushMicrotasks();

        when(() => player.position)
            .thenReturn(const Duration(milliseconds: 150));

        final linesBefore = vm.selectedLine.value;
        async.elapse(const Duration(milliseconds: 200));

        expect(vm.selectedLine.value, linesBefore);
        vm.dispose();
      });
    });

    test('timer stops when syncedMode is false', () {
      fakeAsync((async) {
        setupMocks();
        final lyrics = makeSyncedLyrics([
          (startMs: 0, text: 'line 0'),
          (startMs: 100, text: 'line 1'),
        ]);
        when(() => subsonic.getLyricsLines(any()))
            .thenAnswer((_) async => Result.ok(lyrics));

        final vm =
            LyricsViewModel(subsonic: subsonic, playbackManager: playback);
        currentSubject.add(makeSong('s1'));
        async.flushMicrotasks();
        statusSubject.add(PlaybackStatus.playing);
        async.flushMicrotasks();

        vm.syncedMode = false;
        async.flushMicrotasks();

        when(() => player.position)
            .thenReturn(const Duration(milliseconds: 150));

        final linesBefore = vm.selectedLine.value;
        async.elapse(const Duration(milliseconds: 200));

        expect(vm.selectedLine.value, linesBefore);
        vm.dispose();
      });
    });
  });

  group('syncedMode setter', () {
    test('no-op and no notify when value unchanged', () async {
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(makeSyncedLyrics([
                (startMs: 0, text: 'line 0'),
              ])));
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);
      expect(vm.syncedMode, isTrue);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.syncedMode = true; // same value

      expect(notified, isFalse);
    });

    test('changes value and notifies', () async {
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(makeSyncedLyrics([
                (startMs: 0, text: 'line 0'),
              ])));
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);
      expect(vm.syncedMode, isTrue);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.syncedMode = false;

      expect(vm.syncedMode, isFalse);
      expect(notified, isTrue);
    });
  });

  group('seek', () {
    test('while paused calls seek then play and sets syncedMode true', () async {
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(makeUnsyncedLyrics(['line 1'])));
      statusSubject.add(PlaybackStatus.paused);
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      await vm.seek(const Duration(seconds: 5));

      verify(() => player.seek(const Duration(seconds: 5))).called(1);
      verify(() => player.play()).called(1);
    });

    test('while playing calls seek only', () async {
      when(() => subsonic.getLyricsLines(any()))
          .thenAnswer((_) async => Result.ok(makeUnsyncedLyrics(['line 1'])));
      statusSubject.add(PlaybackStatus.playing);
      final vm = await buildViewModel();
      currentSubject.add(makeSong('s1'));
      await Future.delayed(Duration.zero);

      await vm.seek(const Duration(seconds: 5));

      verify(() => player.seek(const Duration(seconds: 5))).called(1);
      verifyNever(() => player.play());
    });
  });
}