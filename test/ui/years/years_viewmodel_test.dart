import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/years/years_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

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
  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late StreamController<void> debounced;

  setUp(() {
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    debounced = StreamController<void>.broadcast();

    when(() => musicFolders.debounced).thenAnswer((_) => debounced.stream);
    when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
        .thenAnswer((_) async => const Result.ok(<Album>[]));
  });

  tearDown(() async {
    await debounced.close();
  });

  YearsViewModel buildViewModel() => YearsViewModel(
        subsonic: subsonic,
        musicFolders: musicFolders,
      );

  group('defaults', () {
    test('fromYear is now-10 and toYear is now', () {
      final now = DateTime.now().year;
      final vm = buildViewModel();

      expect(vm.fromYear, now - 10);
      expect(vm.toYear, now);
    });

    test('does not fetch on construction', () async {
      buildViewModel();
      await Future.delayed(Duration.zero);

      verifyNever(
        () => subsonic.getAlbumsByYears(any(), any(), any(), any()),
      );
    });
  });

  group('fromYear setter', () {
    test('shifts toYear by the same delta and triggers refresh', () async {
      final vm = buildViewModel();
      vm.fromYear = 2010;
      await Future.delayed(Duration.zero); // settle initial refresh from setter

      // Now from=2010, to=2010+(now-(now-10))=now
      final expectedTo = vm.fromYear + 10; // delta = 10 from default
      expect(vm.toYear, expectedTo);
    });

    test('shifts toYear correctly for arbitrary delta', () async {
      final vm = buildViewModel();
      final initialFrom = vm.fromYear; // now - 10
      final initialTo = vm.toYear;   // now

      vm.fromYear = initialFrom + 5; // delta = +5

      expect(vm.toYear, initialTo + 5);
      expect(vm.fromYear, initialFrom + 5);
    });

    test('emits loading then success on change', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1')]));

      final vm = buildViewModel();
      // Settle construction (no initial fetch in constructor)
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      vm.fromYear = vm.fromYear + 1;
      await Future.delayed(Duration.zero);

      expect(statuses, contains(FetchStatus.loading));
      expect(statuses.last, FetchStatus.success);
    });

    test('triggers a repo call with updated years', () async {
      final vm = buildViewModel();
      clearInteractions(subsonic);

      vm.fromYear = 2000;
      await Future.delayed(Duration.zero);

      final captured = verify(
        () => subsonic.getAlbumsByYears(
          captureAny(),
          captureAny(),
          any(),
          any(),
        ),
      ).captured;
      expect(captured[0], 2000); // fromYear
      expect(captured[1], vm.toYear); // toYear (shifted)
    });
  });

  group('toYear setter', () {
    test('updates toYear and triggers refresh', () async {
      final vm = buildViewModel();
      clearInteractions(subsonic);

      vm.toYear = 2030;
      await Future.delayed(Duration.zero);

      expect(vm.toYear, 2030);
      verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), any()),
      ).called(1);
    });

    test('passes updated toYear to repo', () async {
      final vm = buildViewModel();
      clearInteractions(subsonic);

      vm.toYear = 1995;
      await Future.delayed(Duration.zero);

      final captured = verify(
        () => subsonic.getAlbumsByYears(
          any(),
          captureAny(),
          any(),
          any(),
        ),
      ).captured;
      expect(captured.single, 1995);
    });
  });

  group('pagination', () {
    test('nextPage performs the initial load at offset=0', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1')]));

      final vm = buildViewModel();
      await vm.nextPage();

      expect(vm.status, FetchStatus.success);
      expect(vm.albums.length, 1);
      final offsets = verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), captureAny()),
      ).captured;
      expect(offsets.single, 0);
    });

    test('first fetch uses offset=0, nextPage uses offset=100', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer(
        (_) async => Result.ok(List.generate(100, (i) => makeAlbum('$i'))),
      );

      final vm = buildViewModel();
      await vm.refresh();

      final offsets1 = verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), captureAny()),
      ).captured;
      expect(offsets1.single, 0);

      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => const Result.ok([]));
      await vm.nextPage();

      final offsets2 = verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), captureAny()),
      ).captured;
      expect(offsets2.single, 100);
    });

    test('_reachedEnd set when result < 100, nextPage then no-ops', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1')]));

      final vm = buildViewModel();
      await vm.refresh();
      clearInteractions(subsonic);

      await vm.nextPage();

      verifyNever(
          () => subsonic.getAlbumsByYears(any(), any(), any(), any()));
    });

    test('loading guard prevents concurrent fetch', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      vm.refresh(); // starts fetch, status = loading
      await vm.refresh(); // finds loading, returns early

      completer.complete(const Result.ok([]));
      await Future.delayed(Duration.zero);

      verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), any()),
      ).called(1);
    });
  });

  group('failure', () {
    test('sets status to failure, notifies, and passes correct args', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.error(Exception('network error')));

      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.refresh();

      expect(vm.status, FetchStatus.failure);
      expect(statuses, contains(FetchStatus.failure));

      final captured = verify(
        () => subsonic.getAlbumsByYears(
          captureAny(),
          captureAny(),
          captureAny(),
          captureAny(),
        ),
      ).captured;
      expect(captured[0], vm.fromYear);
      expect(captured[1], vm.toYear);
      expect(captured[2], 100); // page size
      expect(captured[3], 0);   // offset for first page
    });
  });

  group('music folder debounced', () {
    test('triggers a refresh', () async {
      buildViewModel();
      clearInteractions(subsonic);

      debounced.add(null);
      await Future.delayed(Duration.zero);

      verify(
        () => subsonic.getAlbumsByYears(any(), any(), any(), any()),
      ).called(1);
    });

    test('no longer refreshes after dispose', () async {
      final vm = buildViewModel();
      clearInteractions(subsonic);

      vm.dispose();
      debounced.add(null);
      await Future.delayed(Duration.zero);

      verifyNever(
        () => subsonic.getAlbumsByYears(any(), any(), any(), any()),
      );
    });
  });

  group('status sequence', () {
    test('emits loading then success and populates albums', () async {
      when(() => subsonic.getAlbumsByYears(any(), any(), any(), any()))
          .thenAnswer((_) async => Result.ok([makeAlbum('1')]));

      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.refresh();

      expect(statuses, contains(FetchStatus.loading));
      expect(statuses.last, FetchStatus.success);
      expect(vm.albums.length, 1);
    });
  });
}