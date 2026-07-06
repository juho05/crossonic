import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/common/dialogs/album_release_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

Album makeAlbum({
  String id = 'a',
  ReleaseType releaseType = ReleaseType.album,
  Date? originalDate,
  Date? releaseDate,
  String? version,
}) => Album(
      id: id,
      name: 'Album $id',
      coverId: 'c',
      songs: null,
      songCount: 0,
      displayArtist: 'A',
      artists: const [],
      discTitles: const {},
      releaseType: releaseType,
      releaseDate: releaseDate,
      originalDate: originalDate,
      version: version,
      musicBrainzId: null,
    );

void main() {
  late MockSubsonicRepository subsonic;
  late MockServerSupport supports;
  final baseAlbum = makeAlbum(id: 'base');

  setUp(() {
    subsonic = MockSubsonicRepository();
    supports = MockServerSupport();
    when(() => subsonic.supports).thenReturn(supports);
  });

  AlbumReleaseDialogViewModel buildViewModel({List<Album>? alternatives}) =>
      AlbumReleaseDialogViewModel(
        subsonicRepository: subsonic,
        album: baseAlbum,
        alternatives: alternatives,
      );

  group('explicit alternatives provided', () {
    test('success immediately, no fetch, sorted', () async {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final alternatives = [
        makeAlbum(id: 'b', releaseDate: Date(year: 2020)),
        makeAlbum(id: 'a', releaseDate: Date(year: 2023)),
      ];
      final vm = buildViewModel(alternatives: alternatives);

      expect(vm.status, FetchStatus.success);
      verifyNever(() => subsonic.getAlternateAlbumVersions(any()));
      expect(vm.alternatives.first.id, 'a',
          reason: 'newest release date should be first');
      vm.dispose();
    });

    test('explicit empty list -> success, empty, no fetch', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final vm = buildViewModel(alternatives: []);

      expect(vm.status, FetchStatus.success);
      expect(vm.alternatives, isEmpty);
      verifyNever(() => subsonic.getAlternateAlbumVersions(any()));
      vm.dispose();
    });
  });

  group('null alternatives + unsupported', () {
    test('success empty, no fetch, notified', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);

      final vm = AlbumReleaseDialogViewModel(
        subsonicRepository: subsonic,
        album: baseAlbum,
        alternatives: null,
      );

      expect(vm.status, FetchStatus.success);
      expect(vm.alternatives, isEmpty);
      verifyNever(() => subsonic.getAlternateAlbumVersions(any()));
      vm.dispose();
    });
  });

  group('null alternatives + supported', () {
    test('initial->loading->success, sorted+populated', () async {
      when(() => supports.getAlternateAlbumVersions).thenReturn(true);
      final fetchedAlbums = [
        makeAlbum(id: 'x', releaseDate: Date(year: 2019)),
        makeAlbum(id: 'y', releaseDate: Date(year: 2022)),
      ];
      when(() => subsonic.getAlternateAlbumVersions('base'))
          .thenAnswer((_) async => Result.ok(fetchedAlbums));

      final vm = buildViewModel();
      expect(vm.status, FetchStatus.loading);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(statuses, contains(FetchStatus.success));
      expect(vm.status, FetchStatus.success);
      expect(vm.alternatives.first.id, 'y',
          reason: 'newest release date should be first');
      verify(() => subsonic.getAlternateAlbumVersions('base')).called(1);
      vm.dispose();
    });

    test('empty fetch result -> success, empty', () async {
      when(() => supports.getAlternateAlbumVersions).thenReturn(true);
      when(() => subsonic.getAlternateAlbumVersions('base'))
          .thenAnswer((_) async => const Result.ok([]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.alternatives, isEmpty);
      vm.dispose();
    });

    test('loading->failure when fetch fails, list stays empty', () async {
      when(() => supports.getAlternateAlbumVersions).thenReturn(true);
      when(() => subsonic.getAlternateAlbumVersions(any()))
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(vm.alternatives, isEmpty);
      vm.dispose();
    });
  });

  group('sort order', () {
    test('both dates: newest release date first', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final a2020 = makeAlbum(id: 'a', releaseDate: Date(year: 2020));
      final a2023 = makeAlbum(id: 'b', releaseDate: Date(year: 2023));
      final a2015 = makeAlbum(id: 'c', releaseDate: Date(year: 2015));
      final vm = buildViewModel(alternatives: [a2020, a2023, a2015]);

      expect(vm.alternatives.map((a) => a.id).toList(), ['b', 'a', 'c']);
      vm.dispose();
    });

    test('one date: date-holder first, null last', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final withDate = makeAlbum(id: 'a', releaseDate: Date(year: 2020));
      final noDate = makeAlbum(id: 'b');
      final vm = buildViewModel(alternatives: [noDate, withDate]);

      expect(vm.alternatives.first.id, 'a');
      vm.dispose();
    });

    test('no dates, both versions: version ascending', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final vDeluxe = makeAlbum(id: 'a', version: 'Deluxe');
      final vBonus = makeAlbum(id: 'b', version: 'Bonus');
      final vm = buildViewModel(alternatives: [vDeluxe, vBonus]);

      expect(vm.alternatives.map((a) => a.version).toList(), ['Bonus', 'Deluxe']);
      vm.dispose();
    });

    test('no dates, one version: version-holder first', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final withVersion = makeAlbum(id: 'a', version: 'Special');
      final noVersion = makeAlbum(id: 'b');
      final vm = buildViewModel(alternatives: [noVersion, withVersion]);

      expect(vm.alternatives.first.id, 'a');
      vm.dispose();
    });

    test('date beats version: date-holder sorts before version-only', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final versionOnly = makeAlbum(id: 'a', version: 'Deluxe');
      final dateOnly = makeAlbum(id: 'b', releaseDate: Date(year: 2000));
      final vm = buildViewModel(alternatives: [versionOnly, dateOnly]);

      expect(vm.alternatives.first.id, 'b',
          reason: 'a release date outranks a version');
      vm.dispose();
    });

    test('no dates, no versions: id ascending', () {
      when(() => supports.getAlternateAlbumVersions).thenReturn(false);
      final albumC = makeAlbum(id: 'c');
      final albumA = makeAlbum(id: 'a');
      final albumB = makeAlbum(id: 'b');
      final vm = buildViewModel(alternatives: [albumC, albumA, albumB]);

      expect(vm.alternatives.map((a) => a.id).toList(), ['a', 'b', 'c']);
      vm.dispose();
    });
  });
}