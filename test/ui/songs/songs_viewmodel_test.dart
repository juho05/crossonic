import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/ui/songs/songs_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

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
  setUpAll(() {
    registerFallbackValue(SongsSortMode.random);
    registerFallbackValue(<String>[]);
    registerFallbackValue(<Song>[]);
  });

  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late MockServerSupport supports;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;
  late StreamController<void> debounced;

  void stubGetRandomSongs({List<Song>? songs}) {
    // Stub with 3 named args (used by _fetch: count, offset, seed)
    when(
      () => subsonic.getRandomSongs(
        count: any(named: 'count'),
        offset: any(named: 'offset'),
        seed: any(named: 'seed'),
      ),
    ).thenAnswer((_) async => Result.ok(songs ?? <Song>[]));
    // Stub with 1 named arg (used by shuffle: only count)
    when(
      () => subsonic.getRandomSongs(count: any(named: 'count')),
    ).thenAnswer((_) async => Result.ok(songs ?? <Song>[]));
  }

  setUp(() {
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    supports = MockServerSupport();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();
    debounced = StreamController<void>.broadcast();

    when(() => musicFolders.debounced).thenAnswer((_) => debounced.stream);
    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.randomSeed).thenReturn(false);
    when(() => supports.emptySearchString).thenReturn(true);
    when(() => supports.getSongs).thenReturn(false);

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => queue.replace(any())).thenAnswer((_) async {});
    when(() => queue.addAll(any(), any())).thenAnswer((_) async {});

    stubGetRandomSongs();
    when(
      () => subsonic.search(
        any(),
        songCount: any(named: 'songCount'),
        songOffset: any(named: 'songOffset'),
        albumCount: any(named: 'albumCount'),
        artistCount: any(named: 'artistCount'),
      ),
    ).thenAnswer(
      (_) async => const Result.ok((
        songs: <Song>[],
        albums: <Album>[],
        artists: <Artist>[],
      )),
    );
    when(() => subsonic.getStarredSongs())
        .thenAnswer((_) async => const Result.ok(<Song>[]));
    when(
      () => subsonic.getSongsByGenre(
        any(),
        count: any(named: 'count'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Result.ok(<Song>[]));
    when(
      () => subsonic.getSongs(
        count: any(named: 'count'),
        genres: any(named: 'genres'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => const Result.ok(<Song>[]));
  });

  tearDown(() async {
    await debounced.close();
  });

  SongsViewModel buildViewModel({
    SongsPageMode mode = SongsPageMode.random,
    String? initialSeed,
  }) =>
      SongsViewModel(
        subsonic: subsonic,
        playbackManager: playback,
        mode: mode,
        musicFolders: musicFolders,
        initialSeed: initialSeed,
      );

  group('constructor', () {
    test('throws when mode is genre', () {
      expect(
        () => SongsViewModel(
          subsonic: subsonic,
          playbackManager: playback,
          mode: SongsPageMode.genre,
          musicFolders: musicFolders,
        ),
        throwsException,
      );
    });

    test('mode=all when !supportsAllMode falls back to random', () async {
      when(() => supports.emptySearchString).thenReturn(false);

      final vm = buildViewModel(mode: SongsPageMode.all);
      await Future.delayed(Duration.zero);

      expect(vm.mode, SongsPageMode.random);
      verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).called(1);
      verifyNever(
        () => subsonic.search(
          any(),
          songCount: any(named: 'songCount'),
          songOffset: any(named: 'songOffset'),
          albumCount: any(named: 'albumCount'),
          artistCount: any(named: 'artistCount'),
        ),
      );
    });
  });

  group('mode routing', () {
    test('random mode calls getRandomSongs', () async {
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).called(1);
    });

    test('all mode calls search with empty string', () async {
      final vm = buildViewModel(mode: SongsPageMode.all);
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      final captured = verify(
        () => subsonic.search(
          captureAny(),
          songCount: any(named: 'songCount'),
          songOffset: any(named: 'songOffset'),
          albumCount: any(named: 'albumCount'),
          artistCount: any(named: 'artistCount'),
        ),
      ).captured;
      expect(captured.single, '');
    });

    test('favorites mode calls getStarredSongs', () async {
      final vm = buildViewModel(mode: SongsPageMode.favorites);
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      verify(() => subsonic.getStarredSongs()).called(1);
    });

    test('genre constructor calls getSongsByGenre with correct genre', () async {
      final vm = SongsViewModel.genre(
        subsonic: subsonic,
        playbackManager: playback,
        musicFolders: musicFolders,
        genre: 'jazz',
      );
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      final captured = verify(
        () => subsonic.getSongsByGenre(
          captureAny(),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
        ),
      ).captured;
      expect(captured.single, 'jazz');
    });
  });

  group('nextPage', () {
    test('no-ops when _reachedEnd', () async {
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero); // fewer than 500 songs → _reachedEnd
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      );
    });

    test('no-ops for favorites mode', () async {
      final vm = buildViewModel(mode: SongsPageMode.favorites);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(() => subsonic.getStarredSongs());
    });

    test('no-ops for random without randomSeed support', () async {
      when(() => supports.randomSeed).thenReturn(false);
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      );
    });

    test('loading guard: concurrent refresh calls result in a single fetch',
        () async {
      final completer = Completer<Result<Iterable<Song>>>();
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) => completer.future);

      final vm = buildViewModel(mode: SongsPageMode.random);
      await vm.refresh(); // status = loading; this no-ops

      completer.complete(const Result.ok([]));
      await Future.delayed(Duration.zero);

      verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).called(1);
    });

    test('pagination: first page offset=0, nextPage offset=500', () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer(
        (_) async => Result.ok(List.generate(500, (i) => makeSong('$i'))),
      );

      when(() => supports.randomSeed).thenReturn(true);
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);

      final offsets1 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: captureAny(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).captured;
      expect(offsets1.single, 0);

      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async => const Result.ok([]));
      await vm.nextPage();

      final offsets2 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: captureAny(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).captured;
      expect(offsets2.single, 500);
    });
  });

  group('refresh seed', () {
    setUp(() {
      when(() => supports.randomSeed).thenReturn(true);
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async => const Result.ok([]));
    });

    test('refresh(keepSeed:true) passes the same seed', () async {
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);

      final seeds1 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: captureAny(named: 'seed'),
        ),
      ).captured;
      final seed1 = seeds1.single;

      await vm.refresh(keepSeed: true);

      final seeds2 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: captureAny(named: 'seed'),
        ),
      ).captured;
      expect(seeds2.single, equals(seed1));
    });

    test('refresh() without keepSeed generates a new seed', () async {
      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);

      final seeds1 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: captureAny(named: 'seed'),
        ),
      ).captured;
      final seed1 = seeds1.single;

      await vm.refresh();

      final seeds2 = verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: captureAny(named: 'seed'),
        ),
      ).captured;
      expect(seed1, isNotNull);
      expect(seeds2.single, isNotNull);
      expect(seeds2.single, isNot(equals(seed1)));
    });
  });

  group('success / failure', () {
    test('success populates songs, sets status, and notifies', () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async =>
          Result.ok([makeSong('a'), makeSong('b'), makeSong('c')]));

      final vm = buildViewModel(mode: SongsPageMode.random);
      var notified = false;
      vm.addListener(() => notified = true);

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.songs.length, 3);
      expect(notified, isTrue);
    });

    test('failure sets status to failure and notifies', () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async => Result.error(Exception('nope')));

      final vm = buildViewModel(mode: SongsPageMode.random);
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(statuses, contains(FetchStatus.failure));
    });
  });

  group('shuffle', () {
    test(
        'random mode calls getRandomSongs(count:500), replaces queue, '
        'calls playOnNextMediaChange', () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async =>
          Result.ok([makeSong('a'), makeSong('b')]));

      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);
      clearInteractions(player);
      clearInteractions(queue);

      when(() => subsonic.getRandomSongs(count: any(named: 'count')))
          .thenAnswer((_) async =>
              Result.ok([makeSong('s1'), makeSong('s2')]));

      final result = await vm.shuffle();

      expect(result, isA<Ok>());
      final countCaptured = verify(
        () => subsonic.getRandomSongs(count: captureAny(named: 'count')),
      ).captured;
      expect(countCaptured.single, 500);
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });

    test('all mode also calls getRandomSongs(count:500)', () async {
      final vm = buildViewModel(mode: SongsPageMode.all);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);
      clearInteractions(player);
      clearInteractions(queue);

      when(() => subsonic.getRandomSongs(count: any(named: 'count')))
          .thenAnswer((_) async => Result.ok([makeSong('s')]));

      await vm.shuffle();

      verify(
        () => subsonic.getRandomSongs(count: any(named: 'count')),
      ).called(1);
    });

    test('genre + getSongs support calls getSongs(sort:random)', () async {
      when(() => supports.getSongs).thenReturn(true);
      when(
        () => subsonic.getSongsByGenre(
          any(),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Result.ok([makeSong('g')]));

      final vm = SongsViewModel.genre(
        subsonic: subsonic,
        playbackManager: playback,
        musicFolders: musicFolders,
        genre: 'rock',
      );
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);
      clearInteractions(player);
      clearInteractions(queue);

      when(
        () => subsonic.getSongs(
          count: any(named: 'count'),
          genres: any(named: 'genres'),
          sort: any(named: 'sort'),
        ),
      ).thenAnswer((_) async => Result.ok([makeSong('r')]));

      final result = await vm.shuffle();

      expect(result, isA<Ok>());
      final sortCaptured = verify(
        () => subsonic.getSongs(
          count: any(named: 'count'),
          genres: any(named: 'genres'),
          sort: captureAny(named: 'sort'),
        ),
      ).captured;
      expect(sortCaptured.single, SongsSortMode.random);
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });

    test('genre without getSongs support shuffles local songs', () async {
      when(
        () => subsonic.getSongsByGenre(
          any(),
          count: any(named: 'count'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => Result.ok([makeSong('1'), makeSong('2'), makeSong('3')]),
      );

      final vm = SongsViewModel.genre(
        subsonic: subsonic,
        playbackManager: playback,
        musicFolders: musicFolders,
        genre: 'blues',
      );
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);
      clearInteractions(player);
      clearInteractions(queue);

      final result = await vm.shuffle();

      expect(result, isA<Ok>());
      verifyNever(
        () => subsonic.getSongs(
          count: any(named: 'count'),
          genres: any(named: 'genres'),
          sort: any(named: 'sort'),
        ),
      );
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });
  });

  group('play', () {
    test('calls playOnNextMediaChange and replaces queue with loaded songs',
        () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async =>
          Result.ok([makeSong('a'), makeSong('b')]));

      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(player);
      clearInteractions(queue);

      vm.play();

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });
  });

  group('addAllToQueue', () {
    test('calls queue.addAll with the loaded songs and given priority',
        () async {
      when(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).thenAnswer((_) async => Result.ok([makeSong('a')]));

      final vm = buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(queue);

      vm.addAllToQueue(true);

      verify(() => queue.addAll(any(), true)).called(1);
    });
  });

  group('music folder debounced', () {
    test('triggers a refresh', () async {
      buildViewModel(mode: SongsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      debounced.add(null);
      await Future.delayed(Duration.zero);

      verify(
        () => subsonic.getRandomSongs(
          count: any(named: 'count'),
          offset: any(named: 'offset'),
          seed: any(named: 'seed'),
        ),
      ).called(1);
    });
  });
}
