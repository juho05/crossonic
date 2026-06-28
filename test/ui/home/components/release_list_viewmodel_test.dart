import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/ui/home/components/release_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeComponentDataSource extends Mock
    implements HomeComponentDataSource<Album> {}

class MockHomeViewModel extends Mock implements HomeViewModel {}

Album makeAlbum(String id) => Album(
      id: id,
      name: 'Album $id',
      coverId: 'c',
      songs: null,
      songCount: 0,
      displayArtist: 'A',
      artists: const [],
      discTitles: const {},
      releaseType: ReleaseType.album,
      releaseDate: null,
      originalDate: null,
      version: null,
      musicBrainzId: null,
    );

void main() {
  late MockHomeComponentDataSource dataSource;
  late MockHomeViewModel homeViewModel;

  setUp(() {
    dataSource = MockHomeComponentDataSource();
    homeViewModel = MockHomeViewModel();
    when(() => homeViewModel.seed).thenReturn(null);
  });

  HomeReleaseListViewModel buildViewModel({Stream<bool>? refreshStream}) =>
      HomeReleaseListViewModel(
        dataSource: dataSource,
        refreshStream: refreshStream,
        homeViewModel: homeViewModel,
      );

  group('construction / initial load', () {
    test('transitions initial->loading->success and populates list', () async {
      final albums = [makeAlbum('a'), makeAlbum('b')];
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(albums));

      final vm = buildViewModel();
      expect(vm.status, FetchStatus.loading);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(statuses, isNotEmpty);
      expect(vm.status, FetchStatus.success);
      expect(vm.albums, albums);
      vm.dispose();
    });

    test('transitions to failure on load error', () async {
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.error(Exception('network error')));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(vm.albums, isEmpty);
      vm.dispose();
    });
  });

  group('re-entrancy guard', () {
    test('double load() results in single get call', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      vm.load();
      completer.complete(Result.ok([makeAlbum('a')]));
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });
  });

  group('refresh after success', () {
    test('does not emit loading, keeps current list, then updates', () async {
      final firstAlbums = [makeAlbum('a')];
      final secondAlbums = [makeAlbum('b'), makeAlbum('c')];
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(firstAlbums));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);
      expect(vm.status, FetchStatus.success);

      final completer = Completer<Result<Iterable<Album>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));
      vm.load();
      expect(statuses, isNot(contains(FetchStatus.loading)));

      completer.complete(Result.ok(secondAlbums));
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.albums, secondAlbums);
      vm.dispose();
    });
  });

  group('refreshStream', () {
    test('refresh stream emission after first load triggers another get', () async {
      final refreshController = StreamController<bool>.broadcast();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Album>[]));

      final vm = buildViewModel(refreshStream: refreshController.stream);
      await Future.delayed(Duration.zero);

      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok([makeAlbum('x')]));
      refreshController.add(false);
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(2);
      vm.dispose();
      await refreshController.close();
    });
  });

  group('count and seed', () {
    test('passes count=20 to data source', () async {
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Album>[]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(20, seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });

    test('passes homeViewModel.seed to data source', () async {
      when(() => homeViewModel.seed).thenReturn('myseed');
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Album>[]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(20, seed: 'myseed')).called(1);
      vm.dispose();
    });
  });

  group('dispose', () {
    test('cancels refresh subscription on dispose', () async {
      final refreshController = StreamController<bool>.broadcast();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Album>[]));

      final vm = buildViewModel(refreshStream: refreshController.stream);
      await Future.delayed(Duration.zero);
      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(1);

      vm.dispose();

      refreshController.add(false);
      await Future.delayed(Duration.zero);

      verifyNever(() => dataSource.get(any(), seed: any(named: 'seed')));
      await refreshController.close();
    });
  });
}