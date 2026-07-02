import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/albums/albums_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

Album makeAlbum(String id) => Album(
      id: id,
      name: 'Album $id',
      coverId: 'cover-$id',
      songs: null,
      songCount: 0,
      displayArtist: 'Artist',
      artists: const [],
      discTitles: const {},
      releaseType: ReleaseType.album,
      releaseDate: null,
      originalDate: null,
      version: null,
      musicBrainzId: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(AlbumsSortMode.alphabetical);
  });

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

  AlbumsViewModel buildViewModel({
    AlbumsPageMode mode = AlbumsPageMode.alphabetical,
    String? initialSeed,
  }) =>
      AlbumsViewModel(
        subsonic: subsonic,
        musicFolders: musicFolders,
        mode: mode,
        initialSeed: initialSeed,
      );

  group('constructor', () {
    test('throws when mode is genre', () {
      expect(
        () => AlbumsViewModel(
          subsonic: subsonic,
          musicFolders: musicFolders,
          mode: AlbumsPageMode.genre,
        ),
        throwsException,
      );
    });
  });

  group('genre constructor', () {
    test(
        'calls getAlbumsByGenre with correct genre, populates albums, notifies',
        () async {
      when(() => subsonic.getAlbumsByGenre(any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1'), makeAlbum('2')]));

      final vm = AlbumsViewModel.genre(
        subsonic: subsonic,
        genre: 'rock',
        musicFolders: musicFolders,
      );
      var notified = false;
      vm.addListener(() => notified = true);

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.albums.length, 2);
      expect(notified, isTrue);
      final captured =
          verify(() => subsonic.getAlbumsByGenre(captureAny(), any(), any()))
              .captured;
      expect(captured.single, 'rock');
    });
  });

  group('mode mapping', () {
    final cases = [
      (AlbumsPageMode.alphabetical, AlbumsSortMode.alphabetical),
      (AlbumsPageMode.favorites, AlbumsSortMode.starred),
      (AlbumsPageMode.frequentlyPlayed, AlbumsSortMode.frequentlyPlayed),
      (AlbumsPageMode.random, AlbumsSortMode.random),
      (AlbumsPageMode.recentlyAdded, AlbumsSortMode.recentlyAdded),
      (AlbumsPageMode.recentlyPlayed, AlbumsSortMode.recentlyPlayed),
    ];

    for (final (pageMode, sortMode) in cases) {
      test('$pageMode maps to $sortMode', () async {
        when(() => subsonic.getAlbums(any(), any(), any(), any()))
            .thenAnswer((_) async => const Result.ok([]));

        buildViewModel(mode: pageMode);
        await Future.delayed(Duration.zero);

        final captured = verify(
          () => subsonic.getAlbums(captureAny(), any(), any(), any()),
        ).captured;
        expect(captured.single, sortMode);
      });
    }
  });

  group('random without randomSeed', () {
    setUp(() {
      when(() => supports.randomSeed).thenReturn(false);
    });

    test('passes count=500', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));

      buildViewModel(mode: AlbumsPageMode.random);
      await Future.delayed(Duration.zero);

      final captured = verify(
        () => subsonic.getAlbums(any(), captureAny(), any(), any()),
      ).captured;
      expect(captured.single, 500);
    });

    test('nextPage no-ops even when not at end', () async {
      // Return a full page so _reachedEnd stays false; this isolates the
      // random-without-seed guard as the sole reason nextPage no-ops.
      when(() => subsonic.getAlbums(any(), any(), any(), any())).thenAnswer(
          (_) async => Result.ok(List.generate(500, (i) => makeAlbum('$i'))));

      final vm = buildViewModel(mode: AlbumsPageMode.random);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(() => subsonic.getAlbums(any(), any(), any(), any()));
    });
  });

  group('pagination', () {
    test('first page uses offset=0, nextPage uses offset=250', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async =>
              Result.ok(List.generate(250, (i) => makeAlbum('$i'))));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      final offsets1 = verify(
        () => subsonic.getAlbums(any(), any(), captureAny(), any()),
      ).captured;
      expect(offsets1.single, 0);

      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));
      await vm.nextPage();

      final offsets2 = verify(
        () => subsonic.getAlbums(any(), any(), captureAny(), any()),
      ).captured;
      expect(offsets2.single, 250);
    });

    test('_reachedEnd set when result < 250, nextPage then no-ops', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1')]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(() => subsonic.getAlbums(any(), any(), any(), any()));
    });

    test('loading guard prevents concurrent fetch', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel(); // triggers first fetch; status = loading
      await vm.refresh(); // finds loading, returns early

      completer.complete(const Result.ok([]));
      await Future.delayed(Duration.zero);

      verify(() => subsonic.getAlbums(any(), any(), any(), any())).called(1);
    });
  });

  group('refresh seed', () {
    setUp(() {
      when(() => supports.randomSeed).thenReturn(true);
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));
    });

    test('refresh(keepSeed:true) passes the same seed', () async {
      final vm = buildViewModel(mode: AlbumsPageMode.random);
      await Future.delayed(Duration.zero);

      final seeds1 = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      final seed1 = seeds1.single;

      await vm.refresh(keepSeed: true);

      final seeds2 = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      expect(seeds2.single, equals(seed1));
    });

    test('refresh() without keepSeed generates a different seed', () async {
      final vm = buildViewModel(mode: AlbumsPageMode.random);
      await Future.delayed(Duration.zero);

      final seeds1 = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      final seed1 = seeds1.single;

      await vm.refresh();

      final seeds2 = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      expect(seed1, isNotNull);
      expect(seeds2.single, isNotNull);
      expect(seeds2.single, isNot(equals(seed1)));
    });
  });

  group('initialSeed', () {
    setUp(() {
      when(() => supports.randomSeed).thenReturn(true);
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));
    });

    test('random mode uses the provided seed for the first fetch', () async {
      buildViewModel(mode: AlbumsPageMode.random, initialSeed: 'my-seed');
      await Future.delayed(Duration.zero);

      final seeds = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      expect(seeds.single, 'my-seed');
    });

    test('seed persists across pages of the initial fetch but not a refresh',
        () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any())).thenAnswer(
          (_) async => Result.ok(List.generate(250, (i) => makeAlbum('$i'))));

      final vm =
          buildViewModel(mode: AlbumsPageMode.random, initialSeed: 'my-seed');
      await Future.delayed(Duration.zero);

      await vm.nextPage();

      // initial fetch (page 0) and its additional page both use the seed
      final seeds = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured;
      expect(seeds, everyElement('my-seed'));

      await vm.refresh();

      final refreshedSeed = verify(
        () => subsonic.getAlbums(any(), any(), any(), captureAny()),
      ).captured.single;
      expect(refreshedSeed, isNot('my-seed'));
    });
  });

  group('mode setter', () {
    test('changing mode refetches with the new sort mode', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));

      final vm = buildViewModel(mode: AlbumsPageMode.alphabetical);
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      vm.mode = AlbumsPageMode.favorites;
      await Future.delayed(Duration.zero);

      final sorts = verify(
        () => subsonic.getAlbums(captureAny(), any(), any(), any()),
      ).captured;
      expect(sorts.single, AlbumsSortMode.starred);
    });

    test('throws when set to genre', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(() => vm.mode = AlbumsPageMode.genre, throwsException);
    });
  });

  group('failure', () {
    test('sets status to failure and notifies', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));

      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(statuses, contains(FetchStatus.failure));
    });
  });

  group('music folder debounced', () {
    test('triggers a refresh', () async {
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));

      buildViewModel();
      await Future.delayed(Duration.zero);
      clearInteractions(subsonic);

      debounced.add(null);
      await Future.delayed(Duration.zero);

      verify(() => subsonic.getAlbums(any(), any(), any(), any())).called(1);
    });
  });

  group('status sequence', () {
    test('emits loading then success', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getAlbums(any(), any(), any(), any()))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      // Construction triggers the fetch synchronously up to the first await,
      // so status is already loading before the listener is attached.
      final statuses = [vm.status];
      vm.addListener(() => statuses.add(vm.status));

      completer.complete(Result.ok([makeAlbum('1')]));
      await Future.delayed(Duration.zero);

      expect(statuses.first, FetchStatus.loading);
      expect(statuses.last, FetchStatus.success);
    });
  });
}