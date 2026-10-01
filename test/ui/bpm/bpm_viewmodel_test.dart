import 'dart:async';

import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/ui/bpm/bpm_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

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

void main() {
  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late MockPlaybackManager playbackManager;
  late MockPlayerManager playerManager;
  late MockQueueManager queueManager;
  late StreamController<void> debounced;

  setUp(() {
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    playbackManager = MockPlaybackManager();
    playerManager = MockPlayerManager();
    queueManager = MockQueueManager();
    debounced = StreamController<void>.broadcast();

    when(() => musicFolders.debounced).thenAnswer((_) => debounced.stream);
    when(() => playbackManager.player).thenReturn(playerManager);
    when(() => playbackManager.queue).thenReturn(queueManager);

    registerFallbackValue(SongsSortMode.random);
    registerFallbackValue(<Song>[]);
  });

  tearDown(() async {
    await debounced.close();
  });

  BpmViewModel buildViewModel() => BpmViewModel(
        subsonic: subsonic,
        playbackManager: playbackManager,
        musicFolders: musicFolders,
      );

  group('bpmRange setter', () {
    test('notifies immediately before debounce fires', () {
      fakeAsync((async) {
        when(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            )).thenAnswer((_) async => const Result.ok([]));

        final vm = buildViewModel();
        var notified = false;
        vm.addListener(() => notified = true);

        vm.bpmRange = const RangeValues(60, 140);

        expect(notified, isTrue);
        verifyNever(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            ));

        async.elapse(const Duration(milliseconds: 500));
      });
    });

    test('calls getSongs after 500ms debounce', () {
      fakeAsync((async) {
        when(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            )).thenAnswer((_) async => const Result.ok([]));

        final vm = buildViewModel();
        vm.bpmRange = const RangeValues(60, 140);

        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            )).called(1);
      });
    });

    test('rapid changes coalesce into a single fetch', () {
      fakeAsync((async) {
        when(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            )).thenAnswer((_) async => const Result.ok([]));

        final vm = buildViewModel();
        vm.bpmRange = const RangeValues(60, 140);
        async.elapse(const Duration(milliseconds: 100));
        vm.bpmRange = const RangeValues(70, 150);
        async.elapse(const Duration(milliseconds: 100));
        vm.bpmRange = const RangeValues(80, 160);

        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        verify(() => subsonic.getSongs(
              sort: any(named: 'sort'),
              count: any(named: 'count'),
              offset: any(named: 'offset'),
              minBpm: any(named: 'minBpm'),
              maxBpm: any(named: 'maxBpm'),
            )).called(1);
      });
    });
  });

  group('boundary conversion', () {
    void stubGetSongs() {
      when(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => const Result.ok([]));
    }

    test('start < 50 -> minBpm=0', () async {
      stubGetSongs();
      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(45, 140);
      await vm.refresh();

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: 0,
            maxBpm: 140,
          )).called(1);
    });

    test('start == 60 -> minBpm=60', () async {
      stubGetSongs();
      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(60, 140);
      await vm.refresh();

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: 60,
            maxBpm: 140,
          )).called(1);
    });

    test('end > 200 -> maxBpm=null', () async {
      stubGetSongs();
      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(60, 205);
      await vm.refresh();

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: 60,
            maxBpm: null,
          )).called(1);
    });

    test('end == 180 -> maxBpm=180', () async {
      stubGetSongs();
      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(60, 180);
      await vm.refresh();

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: 60,
            maxBpm: 180,
          )).called(1);
    });
  });

  group('pagination', () {
    test('first page uses offset 0, nextPage uses offset 500', () async {
      final page1 = List.generate(500, (i) => makeSong('$i'));
      final page2 = [makeSong('500')];

      when(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: 0,
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => Result.ok(page1));

      when(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: 500,
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => Result.ok(page2));

      final vm = buildViewModel();
      await vm.refresh();

      expect(vm.songs, hasLength(500));

      await vm.nextPage();

      expect(vm.songs, hasLength(501));

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: 500,
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).called(1);
    });

    test('_reachedEnd when result < 500: nextPage is a no-op', () async {
      final smallResult = List.generate(3, (i) => makeSong('$i'));

      when(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => Result.ok(smallResult));

      final vm = buildViewModel();
      await vm.refresh();

      await vm.nextPage();

      verify(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).called(1);
    });
  });

  test('loading guard: concurrent refresh calls result in single fetch',
      () async {
    final completer = Completer<Result<List<Song>>>();
    when(() => subsonic.getSongs(
          sort: any(named: 'sort'),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          minBpm: any(named: 'minBpm'),
          maxBpm: any(named: 'maxBpm'),
        )).thenAnswer((_) => completer.future);

    final vm = buildViewModel();
    final f1 = vm.refresh();
    final f2 = vm.refresh();
    completer.complete(const Result.ok([]));
    await Future.wait([f1, f2]);

    verify(() => subsonic.getSongs(
          sort: any(named: 'sort'),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          minBpm: any(named: 'minBpm'),
          maxBpm: any(named: 'maxBpm'),
        )).called(1);
  });

  test('failure: status failure, notified', () async {
    when(() => subsonic.getSongs(
          sort: any(named: 'sort'),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          minBpm: any(named: 'minBpm'),
          maxBpm: any(named: 'maxBpm'),
        )).thenAnswer((_) async => Result.error(Exception('fail')));

    final vm = buildViewModel();
    var notified = false;
    vm.addListener(() => notified = true);

    await vm.refresh();

    expect(vm.status, FetchStatus.failure);
    expect(notified, isTrue);
  });

  group('shuffle', () {
    test('calls getSongs with random sort and boundary conversion; on Ok replaces queue',
        () async {
      final songs = [makeSong('a'), makeSong('b')];
      when(() => subsonic.getSongs(
            sort: SongsSortMode.random,
            count: 500,
            minBpm: 60,
            maxBpm: 140,
          )).thenAnswer((_) async => Result.ok(songs));
      when(() => playerManager.playOnNextMediaChange()).thenReturn(null);
      when(() => queueManager.replace(any())).thenAnswer((_) async {});

      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(60, 140);
      final result = await vm.shuffle();

      expect(result, isA<Ok>());
      verify(() => playerManager.playOnNextMediaChange()).called(1);
      verify(() => queueManager.replace(songs)).called(1);
    });

    test('shuffle with start < 50 -> minBpm=0, end > 200 -> maxBpm=null',
        () async {
      when(() => subsonic.getSongs(
            sort: SongsSortMode.random,
            count: 500,
            minBpm: 0,
            maxBpm: null,
          )).thenAnswer((_) async => const Result.ok([]));
      when(() => playerManager.playOnNextMediaChange()).thenReturn(null);
      when(() => queueManager.replace(any())).thenAnswer((_) async {});

      final vm = buildViewModel();
      vm.bpmRange = const RangeValues(45, 205);
      await vm.shuffle();

      verify(() => subsonic.getSongs(
            sort: SongsSortMode.random,
            count: 500,
            minBpm: 0,
            maxBpm: null,
          )).called(1);
    });

    test('failure result is returned on shuffle error', () async {
      when(() => subsonic.getSongs(
            sort: SongsSortMode.random,
            count: 500,
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => Result.error(Exception('shuffle fail')));

      final vm = buildViewModel();
      final result = await vm.shuffle();

      expect(result, isA<Err>());
      verifyNever(() => playerManager.playOnNextMediaChange());
      verifyNever(() => queueManager.replace(any()));
    });
  });

  group('play / addToQueue', () {
    void stubRefresh(List<Song> songs) {
      when(() => subsonic.getSongs(
            sort: any(named: 'sort'),
            count: any(named: 'count'),
            offset: any(named: 'offset'),
            minBpm: any(named: 'minBpm'),
            maxBpm: any(named: 'maxBpm'),
          )).thenAnswer((_) async => Result.ok(songs));
    }

    test('play: enqueues current songs and plays on next media change',
        () async {
      stubRefresh([makeSong('a'), makeSong('b')]);
      when(() => playerManager.playOnNextMediaChange()).thenReturn(null);
      when(() => queueManager.replace(any())).thenAnswer((_) async {});

      final vm = buildViewModel();
      await vm.refresh();
      vm.play();

      verify(() => playerManager.playOnNextMediaChange()).called(1);
      verify(() => queueManager.replace(vm.songs)).called(1);
    });

    test('addToQueue: forwards current songs and priority flag', () async {
      stubRefresh([makeSong('a')]);
      when(() => queueManager.addAll(any(), any())).thenAnswer((_) async {});

      final vm = buildViewModel();
      await vm.refresh();
      vm.addToQueue(true);

      verify(() => queueManager.addAll(vm.songs, true)).called(1);
    });
  });

  test('music folder debounced event triggers refresh', () async {
    when(() => subsonic.getSongs(
          sort: any(named: 'sort'),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          minBpm: any(named: 'minBpm'),
          maxBpm: any(named: 'maxBpm'),
        )).thenAnswer((_) async => const Result.ok([]));
    buildViewModel();

    debounced.add(null);
    await Future.delayed(Duration.zero);

    verify(() => subsonic.getSongs(
          sort: any(named: 'sort'),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          minBpm: any(named: 'minBpm'),
          maxBpm: any(named: 'maxBpm'),
        )).called(1);
  });
}