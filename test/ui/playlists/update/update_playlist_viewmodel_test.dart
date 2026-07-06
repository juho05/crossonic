import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/ui/playlists/update/update_playlist_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

Playlist makePlaylist({
  String id = 'pl-1',
  String name = 'My Playlist',
  String? comment,
}) =>
    Playlist(
      id: id,
      name: name,
      comment: comment,
      songCount: 0,
      duration: Duration.zero,
      created: DateTime(2024),
      changed: DateTime(2024),
      coverId: null,
      download: false,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(<String>{});
  });

  late MockPlaylistRepository repo;

  setUp(() {
    repo = MockPlaylistRepository();
  });

  UpdatePlaylistViewModel buildViewModel([String id = 'pl-1']) =>
      UpdatePlaylistViewModel(playlistRepository: repo, playlistId: id);

  Future<void> settle() async {
    await Future.delayed(Duration.zero);
  }

  group('_load', () {
    test('populates oldName and oldDescription after settle', () async {
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((
          playlist: makePlaylist(name: 'Cool Mix', comment: 'Summer vibes'),
          tracks: const [],
        )),
      );

      final vm = buildViewModel();
      await settle();

      expect(vm.oldName, 'Cool Mix');
      expect(vm.oldDescription, 'Summer vibes');
    });

    test('null comment maps to empty string', () async {
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((
          playlist: makePlaylist(comment: null),
          tracks: const [],
        )),
      );

      final vm = buildViewModel();
      await settle();

      expect(vm.oldDescription, '');
    });

    test('Err: fields stay empty, no throw', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => Result.error(Exception('db fail')));

      final vm = buildViewModel();
      await settle();

      expect(vm.oldName, '');
      expect(vm.oldDescription, '');
    });

    test('Ok(null): fields stay empty, no throw', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));

      final vm = buildViewModel();
      await settle();

      expect(vm.oldName, '');
      expect(vm.oldDescription, '');
    });

    test('_load success does NOT notify listeners', () async {
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((
          playlist: makePlaylist(name: 'Test'),
          tracks: const [],
        )),
      );

      final vm = buildViewModel();
      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      await settle();

      expect(notifyCount, 0);
    });
  });

  group('update', () {
    setUp(() {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));
      when(
        () => repo.updatePlaylistMetadata(
          any(),
          name: any(named: 'name'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
    });

    test('toggles loading true->false and passes args', () async {
      final vm = buildViewModel();
      await settle();

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.loading));

      await vm.update('New Name', 'New Desc');

      expect(seen, [true, false]);
      verify(
        () => repo.updatePlaylistMetadata(
          'pl-1',
          name: 'New Name',
          comment: 'New Desc',
        ),
      ).called(1);
    });

    test('returns repo result on Ok', () async {
      final vm = buildViewModel();
      await settle();

      final result = await vm.update('Name', 'Desc');

      expect(result, isA<Ok>());
    });

    test('returns repo result on Err', () async {
      when(
        () => repo.updatePlaylistMetadata(
          any(),
          name: any(named: 'name'),
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => Result.error(Exception('fail')));

      final vm = buildViewModel();
      await settle();

      final result = await vm.update('Name', 'Desc');

      expect(result, isA<Err>());
      expect(vm.loading, isFalse);
    });

    test('finally resets loading when repo throws', () async {
      when(
        () => repo.updatePlaylistMetadata(
          any(),
          name: any(named: 'name'),
          comment: any(named: 'comment'),
        ),
      ).thenThrow(Exception('unexpected'));

      final vm = buildViewModel();
      await settle();

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.loading));

      expect(() => vm.update('Name', 'Desc'), throwsException);
      await Future.delayed(Duration.zero);

      expect(vm.loading, isFalse);
      expect(seen, containsAll([true, false]));
    });
  });
}