import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/genre.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/genres/genres_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

void main() {
  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late MockServerSupport supports;
  late StreamController<void> debounced;

  setUp(() {
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    supports = MockServerSupport();
    debounced = StreamController<void>.broadcast();

    when(() => musicFolders.debounced).thenAnswer((_) => debounced.stream);
    when(() => subsonic.supports).thenReturn(supports);
  });

  tearDown(() async {
    await debounced.close();
  });

  GenresViewModel buildViewModel() => GenresViewModel(
        subsonic: subsonic,
        musicFolders: musicFolders,
      );

  group('load', () {
    test('success: genres set, largestSongCount, largestAlbumCount, notified',
        () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 10, albumCount: 5),
          Genre(name: 'Jazz', songCount: 3, albumCount: 8),
          Genre(name: 'Pop', songCount: 7, albumCount: 2),
        ]),
      );
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.load();

      expect(vm.status, FetchStatus.success);
      expect(vm.genres, hasLength(3));
      expect(vm.largestSongCount, 10);
      expect(vm.largestAlbumCount, 8);
      expect(notified, isTrue);
    });

    test('failure: status failure, genres empty, notified', () async {
      when(() => subsonic.getGenres())
          .thenAnswer((_) async => Result.error(Exception('network error')));
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.load();

      expect(vm.status, FetchStatus.failure);
      expect(vm.genres, isEmpty);
      expect(notified, isTrue);
    });

    test('ignores a re-entrant load while one is already in progress', () async {
      final completer = Completer<Result<List<Genre>>>();
      when(() => subsonic.getGenres()).thenAnswer((_) => completer.future);
      final vm = buildViewModel();

      final first = vm.load(); // sets status to loading, then awaits
      final second = vm.load(); // status == loading -> returns immediately

      completer.complete(
        Result.ok([Genre(name: 'Rock', songCount: 1, albumCount: 1)]),
      );
      await Future.wait([first, second]);

      verify(() => subsonic.getGenres()).called(1);
    });

    test('notifies with loading then success status sequence', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([Genre(name: 'Rock', songCount: 5, albumCount: 3)]),
      );
      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.load();

      expect(statuses, contains(FetchStatus.loading));
      expect(statuses.last, FetchStatus.success);
    });

    test('alphabetical sort is case-insensitive', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 1, albumCount: 1),
          Genre(name: 'ambient', songCount: 1, albumCount: 1),
          Genre(name: 'Blues', songCount: 1, albumCount: 1),
        ]),
      );
      final vm = buildViewModel();

      await vm.load();

      expect(vm.sortMode, GenresSortMode.alphabetical);
      expect(vm.genres.map((g) => g.name), ['ambient', 'Blues', 'Rock']);
    });

    test('songCount sort is descending', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 5, albumCount: 1),
          Genre(name: 'Jazz', songCount: 20, albumCount: 1),
          Genre(name: 'Pop', songCount: 1, albumCount: 1),
        ]),
      );
      final vm = buildViewModel();
      await vm.load();

      vm.sortMode = GenresSortMode.songCount;

      expect(vm.genres.map((g) => g.songCount), [20, 5, 1]);
    });

    test('albumCount sort is descending', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 1, albumCount: 3),
          Genre(name: 'Jazz', songCount: 1, albumCount: 9),
          Genre(name: 'Pop', songCount: 1, albumCount: 1),
        ]),
      );
      final vm = buildViewModel();
      await vm.load();

      vm.sortMode = GenresSortMode.albumCount;

      expect(vm.genres.map((g) => g.albumCount), [9, 3, 1]);
    });
  });

  group('sortMode setter', () {
    test('no-op when same non-random mode: does not notify', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([Genre(name: 'Rock', songCount: 1, albumCount: 1)]),
      );
      final vm = buildViewModel();
      await vm.load();

      var notified = false;
      vm.addListener(() => notified = true);

      vm.sortMode = GenresSortMode.alphabetical;

      expect(notified, isFalse);
    });

    test('random -> random reshuffles and notifies', () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 1, albumCount: 1),
          Genre(name: 'Jazz', songCount: 2, albumCount: 2),
          Genre(name: 'Pop', songCount: 3, albumCount: 3),
        ]),
      );
      final vm = buildViewModel();
      await vm.load();

      vm.sortMode = GenresSortMode.random;

      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.sortMode = GenresSortMode.random;

      expect(notifyCount, 1);
      expect(vm.genres, hasLength(3));
    });

    test('switching to a different non-random mode re-sorts and notifies',
        () async {
      when(() => subsonic.getGenres()).thenAnswer(
        (_) async => Result.ok([
          Genre(name: 'Rock', songCount: 5, albumCount: 1),
          Genre(name: 'Jazz', songCount: 20, albumCount: 1),
        ]),
      );
      final vm = buildViewModel();
      await vm.load();

      expect(vm.sortMode, GenresSortMode.alphabetical);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.sortMode = GenresSortMode.songCount;

      expect(notified, isTrue);
      expect(vm.genres.first.name, 'Jazz');
    });
  });

  test('music folder debounced event triggers load', () async {
    when(() => subsonic.getGenres())
        .thenAnswer((_) async => Result.ok([]));
    buildViewModel();

    debounced.add(null);
    await Future.delayed(Duration.zero);

    verify(() => subsonic.getGenres()).called(1);
  });

  test('dispose stops handling music folder events', () async {
    when(() => subsonic.getGenres()).thenAnswer((_) async => Result.ok([]));
    final vm = buildViewModel();

    vm.dispose();

    debounced.add(null);
    await Future.delayed(Duration.zero);

    verifyNever(() => subsonic.getGenres());
  });
}