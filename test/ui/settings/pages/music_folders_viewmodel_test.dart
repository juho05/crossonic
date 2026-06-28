import 'package:crossonic/data/repositories/subsonic/models/music_folder.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/settings/pages/music_folders_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

MusicFolder makeFolder(int id, {String? name}) =>
    MusicFolder(id: id, name: name ?? 'Folder $id');

void main() {
  setUpAll(() {
    registerFallbackValue(<int>{});
  });

  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository repo;
  late MockServerSupport supports;

  setUp(() {
    subsonic = MockSubsonicRepository();
    repo = MockMusicFoldersRepository();
    supports = MockServerSupport();

    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.multipleActiveMusicFolders).thenReturn(false);
    when(() => repo.selected).thenReturn({});
    when(() => repo.addListener(any())).thenReturn(null);
    when(() => repo.removeListener(any())).thenReturn(null);
  });

  MusicFoldersViewModel buildViewModel() =>
      MusicFoldersViewModel(subsonic: subsonic, repo: repo);

  group('_load', () {
    test('success: status success, musicFolders populated, notified', () async {
      final folders = [makeFolder(1), makeFolder(2)];
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => Result.ok(folders));

      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.musicFolders, folders);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });

    test('failure: status failure, notified', () async {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => Result.error(Exception('network')));

      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('toggle', () {
    setUp(() {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => Result.ok([makeFolder(1)]));
      when(() => repo.clear()).thenAnswer((_) async {});
      when(() => repo.select(any())).thenAnswer((_) async {});
      when(() => repo.deselect(any())).thenAnswer((_) async {});
      when(() => repo.setSelected(any())).thenAnswer((_) async {});
    });

    test('toggle(ALL_ID) -> clear', () async {
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.toggle(MusicFoldersViewModel.ALL_ID);

      verify(() => repo.clear()).called(1);
      vm.dispose();
    });

    test('toggle(id) when selected -> deselect', () async {
      when(() => repo.selected).thenReturn({1});
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.toggle(1);

      verify(() => repo.deselect(1)).called(1);
      vm.dispose();
    });

    test('toggle(id) when not selected -> select', () async {
      when(() => repo.selected).thenReturn({});
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.toggle(1);

      verify(() => repo.select(1)).called(1);
      vm.dispose();
    });
  });

  group('select', () {
    setUp(() {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => Result.ok([makeFolder(1)]));
      when(() => repo.clear()).thenAnswer((_) async {});
      when(() => repo.select(any())).thenAnswer((_) async {});
      when(() => repo.setSelected(any())).thenAnswer((_) async {});
    });

    test('select(ALL_ID) -> clear', () async {
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.select(MusicFoldersViewModel.ALL_ID);

      verify(() => repo.clear()).called(1);
      vm.dispose();
    });

    test('select(id) multi-select -> repo.select(id)', () async {
      when(() => supports.multipleActiveMusicFolders).thenReturn(true);
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.select(1);

      verify(() => repo.select(1)).called(1);
      verifyNever(() => repo.setSelected(any()));
      vm.dispose();
    });

    test('select(id) single-select -> repo.setSelected({id})', () async {
      when(() => supports.multipleActiveMusicFolders).thenReturn(false);
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.select(1);

      verify(() => repo.setSelected({1})).called(1);
      verifyNever(() => repo.select(any()));
      vm.dispose();
    });
  });

  group('deselect and clearSelection', () {
    setUp(() {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => const Result.ok([]));
      when(() => repo.deselect(any())).thenAnswer((_) async {});
      when(() => repo.clear()).thenAnswer((_) async {});
    });

    test('deselect delegates to repo.deselect', () async {
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.deselect(42);

      verify(() => repo.deselect(42)).called(1);
      vm.dispose();
    });

    test('clearSelection delegates to repo.clear', () async {
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      await vm.clearSelection();

      verify(() => repo.clear()).called(1);
      vm.dispose();
    });
  });

  group('repo notification', () {
    test('repo notification propagates as VM notification', () async {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => const Result.ok([]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      var notifications = 0;
      vm.addListener(() => notifications++);

      final listener =
          verify(() => repo.addListener(captureAny())).captured.single
              as void Function();
      listener();

      expect(notifications, 1);
      vm.dispose();
    });
  });

  group('musicFolders unmodifiable', () {
    test('musicFolders throws on modification', () async {
      when(() => repo.getMusicFolders())
          .thenAnswer((_) async => Result.ok([makeFolder(1)]));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(
        () => vm.musicFolders.add(makeFolder(99)),
        throwsUnsupportedError,
      );
      vm.dispose();
    });
  });
}