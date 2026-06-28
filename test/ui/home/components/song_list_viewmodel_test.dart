import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/home/components/data_source.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeComponentDataSource extends Mock
    implements HomeComponentDataSource<Song> {}

class MockHomeViewModel extends Mock implements HomeViewModel {}

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

void main() {
  late MockHomeComponentDataSource dataSource;
  late MockHomeViewModel homeViewModel;

  setUp(() {
    dataSource = MockHomeComponentDataSource();
    homeViewModel = MockHomeViewModel();
    when(() => homeViewModel.seed).thenReturn(null);
  });

  HomeSongListViewModel buildViewModel({Stream<bool>? refreshStream}) =>
      HomeSongListViewModel(
        dataSource: dataSource,
        refreshStream: refreshStream,
        homeViewModel: homeViewModel,
      );

  group('construction / initial load', () {
    test('transitions initial->loading->success and populates list', () async {
      final songs = [makeSong('a'), makeSong('b')];
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(songs));

      final vm = buildViewModel();
      expect(vm.status, FetchStatus.loading);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await Future.delayed(Duration.zero);

      expect(statuses, isNotEmpty);
      expect(vm.status, FetchStatus.success);
      expect(vm.songs, songs);
      vm.dispose();
    });

    test('transitions to failure on load error', () async {
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.error(Exception('network error')));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(vm.songs, isEmpty);
      vm.dispose();
    });
  });

  group('re-entrancy guard', () {
    test('double load() results in single get call', () async {
      final completer = Completer<Result<Iterable<Song>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      vm.load();
      completer.complete(Result.ok([makeSong('a')]));
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });
  });

  group('refresh after success', () {
    test('does not emit loading, keeps current list, then updates', () async {
      final firstSongs = [makeSong('a')];
      final secondSongs = [makeSong('b'), makeSong('c')];
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok(firstSongs));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);
      expect(vm.status, FetchStatus.success);

      final completer = Completer<Result<Iterable<Song>>>();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) => completer.future);

      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));
      vm.load();
      expect(statuses, isNot(contains(FetchStatus.loading)));

      completer.complete(Result.ok(secondSongs));
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.songs, secondSongs);
      vm.dispose();
    });
  });

  group('refreshStream', () {
    test('refresh stream emission after first load triggers another get', () async {
      final refreshController = StreamController<bool>.broadcast();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Song>[]));

      final vm = buildViewModel(refreshStream: refreshController.stream);
      await Future.delayed(Duration.zero);

      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => Result.ok([makeSong('x')]));
      refreshController.add(false);
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(any(), seed: any(named: 'seed'))).called(2);
      vm.dispose();
      await refreshController.close();
    });
  });

  group('count and seed', () {
    test('passes count=10 to data source', () async {
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Song>[]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(10, seed: any(named: 'seed'))).called(1);
      vm.dispose();
    });

    test('passes homeViewModel.seed to data source', () async {
      when(() => homeViewModel.seed).thenReturn('myseed');
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Song>[]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      verify(() => dataSource.get(10, seed: 'myseed')).called(1);
      vm.dispose();
    });
  });

  group('dispose', () {
    test('cancels refresh subscription on dispose', () async {
      final refreshController = StreamController<bool>.broadcast();
      when(() => dataSource.get(any(), seed: any(named: 'seed')))
          .thenAnswer((_) async => const Result.ok(<Song>[]));

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