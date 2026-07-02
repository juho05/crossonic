import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/artists/artists_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

Artist makeArtist(String name) => Artist(
      id: 'id-$name',
      name: name,
      coverId: 'cover-$name',
      albums: null,
      albumCount: null,
      genres: const [],
    );

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
    when(() => supports.randomSeed).thenReturn(false);
  });

  tearDown(() async {
    await debounced.close();
  });

  ArtistsViewModel buildViewModel(ArtistsPageMode mode) => ArtistsViewModel(
        subsonic: subsonic,
        mode: mode,
        musicFolders: musicFolders,
      );

  group('load', () {
    test('sorts artists alphabetically and reports success', () async {
      when(() => subsonic.getArtists()).thenAnswer(
        (_) async => Result.ok([
          makeArtist('Charlie'),
          makeArtist('alice'),
          makeArtist('Bob'),
        ]),
      );
      final vm = buildViewModel(ArtistsPageMode.alphabetical);
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.load();

      expect(vm.status, FetchStatus.success);
      expect(vm.artists.map((a) => a.name), ['alice', 'Bob', 'Charlie']);
      expect(notified, isTrue);
    });

    test('uses starred artists in favorites mode', () async {
      when(() => subsonic.getStarredArtists())
          .thenAnswer((_) async => Result.ok([makeArtist('Fav')]));
      final vm = buildViewModel(ArtistsPageMode.favorites);
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.load();

      expect(vm.status, FetchStatus.success);
      expect(vm.artists.single.name, 'Fav');
      expect(notified, isTrue);
      verify(() => subsonic.getStarredArtists()).called(1);
      verifyNever(() => subsonic.getArtists());
    });

    test('reports failure and clears artists when the fetch fails', () async {
      when(() => subsonic.getArtists())
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel(ArtistsPageMode.alphabetical);
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.load();

      expect(vm.status, FetchStatus.failure);
      expect(vm.artists, isEmpty);
      expect(statuses.last, FetchStatus.failure,
          reason: 'listeners notified of the failure state');
    });

    test('notifies listeners while loading and on completion', () async {
      when(() => subsonic.getArtists())
          .thenAnswer((_) async => Result.ok([makeArtist('A')]));
      final vm = buildViewModel(ArtistsPageMode.alphabetical);
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.load();

      expect(statuses, contains(FetchStatus.loading));
      expect(statuses.last, FetchStatus.success);
    });
  });

  group('mode setter', () {
    test('re-fetches when switching to favorites', () async {
      when(() => subsonic.getArtists())
          .thenAnswer((_) async => Result.ok([makeArtist('A')]));
      when(() => subsonic.getStarredArtists())
          .thenAnswer((_) async => Result.ok([makeArtist('Fav')]));
      final vm = buildViewModel(ArtistsPageMode.alphabetical);
      await vm.load();

      var notified = false;
      vm.addListener(() => notified = true);

      vm.mode = ArtistsPageMode.favorites;
      await Future.delayed(Duration.zero);

      expect(vm.mode, ArtistsPageMode.favorites);
      expect(notified, isTrue);
      verify(() => subsonic.getStarredArtists()).called(1);
    });

    test('only re-sorts without re-fetching between non-favorite modes',
        () async {
      when(() => subsonic.getArtists()).thenAnswer(
        (_) async => Result.ok([makeArtist('B'), makeArtist('A')]),
      );
      final vm = buildViewModel(ArtistsPageMode.alphabetical);
      await vm.load();
      expect(vm.artists.map((a) => a.name), ['A', 'B']);

      var notified = false;
      vm.addListener(() => notified = true);

      vm.mode = ArtistsPageMode.random;

      expect(notified, isTrue);
      expect(vm.artists.map((a) => a.name).toSet(), {'A', 'B'});
      verify(() => subsonic.getArtists()).called(1);
    });
  });

  group('music folder changes', () {
    test('reload when the selection changes', () async {
      when(() => subsonic.getArtists())
          .thenAnswer((_) async => Result.ok([makeArtist('A')]));
      buildViewModel(ArtistsPageMode.alphabetical);

      debounced.add(null);
      await Future.delayed(Duration.zero);

      verify(() => subsonic.getArtists()).called(1);
    });

    test('keep the random order across the reload', () async {
      when(() => supports.randomSeed).thenReturn(true);
      final list = List.generate(10, (i) => makeArtist('a$i'));
      when(() => subsonic.getArtists())
          .thenAnswer((_) async => Result.ok(list));
      final vm = buildViewModel(ArtistsPageMode.random);
      await vm.load();
      final firstOrder = vm.artists.map((a) => a.name).toList();

      debounced.add(null);
      await Future.delayed(Duration.zero);

      // asserting a second fetch happened is what makes the equal-order check
      // meaningful: it rules out the reload silently not running
      verify(() => subsonic.getArtists()).called(2);
      expect(vm.artists.map((a) => a.name).toList(), firstOrder);
    });
  });

  test('a plain reload reshuffles random mode with a fresh seed', () async {
    when(() => supports.randomSeed).thenReturn(true);
    final list = List.generate(50, (i) => makeArtist('a$i'));
    when(() => subsonic.getArtists()).thenAnswer((_) async => Result.ok(list));
    final vm = buildViewModel(ArtistsPageMode.random);
    await vm.load();
    final firstOrder = vm.artists.map((a) => a.name).toList();

    await vm.load();

    expect(vm.artists.map((a) => a.name).toList(), isNot(firstOrder));
  });

  test('random mode reproduces the same order for the same initial seed',
      () async {
    when(() => supports.randomSeed).thenReturn(true);
    final list = List.generate(10, (i) => makeArtist('a$i'));
    when(() => subsonic.getArtists()).thenAnswer((_) async => Result.ok(list));

    ArtistsViewModel makeVm() => ArtistsViewModel(
          subsonic: subsonic,
          mode: ArtistsPageMode.random,
          musicFolders: musicFolders,
          initialSeed: 'shared-seed',
        );

    final vm1 = makeVm();
    await vm1.load();
    final vm2 = makeVm();
    await vm2.load();

    final order = vm1.artists.map((a) => a.name).toList();
    expect(vm2.artists.map((a) => a.name).toList(), order);
    expect(order, isNot(list.map((a) => a.name).toList()),
        reason: 'the seed must actually shuffle, not keep source order');
  });

  test('ignores a concurrent fetch while one is already in flight', () async {
    final completer = Completer<Result<Iterable<Artist>>>();
    when(() => subsonic.getArtists()).thenAnswer((_) => completer.future);
    final vm = buildViewModel(ArtistsPageMode.alphabetical);

    final first = vm.load();
    final second = vm.load();
    completer.complete(Result.ok([makeArtist('A')]));
    await Future.wait([first, second]);

    verify(() => subsonic.getArtists()).called(1);
  });
}