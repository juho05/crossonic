import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/ui/home/components/artist_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeComponentDataSource extends Mock
    implements HomeComponentDataSource<Artist> {}

class MockHomeViewModel extends Mock implements HomeViewModel {}

Artist makeArtist(String id) => Artist(
      id: id,
      name: 'Artist $id',
      coverId: 'cover-$id',
      albums: null,
      albumCount: null,
      genres: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<Artist>[]);
  });

  late MockHomeComponentDataSource dataSource;
  late MockHomeViewModel homeViewModel;

  setUp(() {
    dataSource = MockHomeComponentDataSource();
    homeViewModel = MockHomeViewModel();
    when(() => homeViewModel.seed).thenReturn(null);
  });

  HomeArtistListViewModel buildViewModel({Stream<bool>? refreshStream}) =>
      HomeArtistListViewModel(
        dataSource: dataSource,
        refreshStream: refreshStream,
        homeViewModel: homeViewModel,
      );

  group('construction / initial load', () {
    test('transitions initial->loading->success and populates list', () async {
      final artists = [makeArtist('a'), makeArtist('b')];
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(artists));

      final vm = buildViewModel();
      // load() runs synchronously up to the first await, so status is loading now
      expect(vm.status, FetchStatus.loading);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(statuses, isNotEmpty);
      expect(vm.status, FetchStatus.success);
      expect(vm.artists, artists);
      vm.dispose();
    });

    test('transitions to failure on load error', () async {
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.error(Exception('network error')));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(vm.artists, isEmpty);
      vm.dispose();
    });
  });

  group('re-entrancy guard', () {
    test('double load() results in single get call', () async {
      final completer = Completer<Result<Iterable<Artist>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      vm.load(); // second call while first is in flight
      completer.complete(Result.ok([makeArtist('a')]));
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });
  });

  group('refresh after success', () {
    test('does not emit loading, keeps current list, then updates', () async {
      final firstArtists = [makeArtist('a')];
      final secondArtists = [makeArtist('b'), makeArtist('c')];
      final completer = Completer<Result<Iterable<Artist>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(firstArtists));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);
      expect(vm.status, FetchStatus.success);

      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));
      vm.load();
      // While second load is in-flight, should not go back to loading
      expect(statuses, isNot(contains(FetchStatus.loading)));

      completer.complete(Result.ok(secondArtists));
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.artists, secondArtists);
      vm.dispose();
    });
  });

  group('refreshStream', () {
    test('refresh stream emission after first load triggers another get', () async {
      final refreshController = StreamController<bool>.broadcast();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Artist>[]));

      final vm = buildViewModel(refreshStream: refreshController.stream);
      await Future.delayed(Duration.zero);

      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok([makeArtist('x')]));
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
          .thenAnswer((_) async => const Result.ok(<Artist>[]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(20, seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });

    test('passes homeViewModel.seed to data source', () async {
      when(() => homeViewModel.seed).thenReturn('myseed');
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Artist>[]));

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
          .thenAnswer((_) async => const Result.ok(<Artist>[]));

      final vm = buildViewModel(refreshStream: refreshController.stream);
      await Future.delayed(Duration.zero);
      vm.dispose();
      clearInteractions(dataSource);

      // After dispose, stream emission should not trigger more loads
      refreshController.add(false);
      await Future.delayed(Duration.zero);

      verifyNever(() => dataSource.get(any(), seed: any(named: 'seed')));
      await refreshController.close();
    });
  });
}