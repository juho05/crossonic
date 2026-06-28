import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

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

Playlist makePlaylist(String id, {String name = 'Playlist'}) => Playlist(
      id: id,
      name: name,
      comment: null,
      songCount: 0,
      duration: Duration.zero,
      created: DateTime(2024),
      changed: DateTime(2024),
      coverId: null,
      download: false,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(makePlaylist('__fallback__'));
    registerFallbackValue(<String>{});
    registerFallbackValue(PlaylistOrderBy.alphabetical);
  });

  late MockPlaylistRepository repo;

  setUp(() {
    repo = MockPlaylistRepository();
    when(
      () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
    ).thenAnswer((_) async => const Result.ok([]));
    when(() => repo.getCountOfSongInPlaylists(any()))
        .thenAnswer((_) async => const Result.ok({}));
    when(() => repo.refresh()).thenAnswer((_) async {});
    when(() => repo.addTracks(any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.getTrackIdsInPlaylist(any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.removeLastOccurrenceOfTrack(any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
  });

  AddToPlaylistViewModel buildViewModel({List<Song> songs = const []}) =>
      AddToPlaylistViewModel(
        repository: repo,
        songLoader: () async => Result.ok(songs),
      );

  Future<void> settle() async {
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
  }

  group('_load', () {
    test('success: status success, songs and playlists loaded', () async {
      final pl = makePlaylist('pl-1', name: 'Faves');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      final song = makeSong('s1');

      final vm = buildViewModel(songs: [song]);
      await settle();

      expect(vm.status, FetchStatus.success);
      expect(vm.songs, contains(song));
      expect(vm.playlists, contains(pl));
    });

    test('single-song: loads in-playlist counts', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getCountOfSongInPlaylists('s1'))
          .thenAnswer((_) async => const Result.ok({'pl-1': 3}));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      expect(vm.status, FetchStatus.success);
      expect(vm.songInPlaylistCounts['pl-1'], 3);
      verify(() => repo.getCountOfSongInPlaylists('s1')).called(1);
    });

    test('success: repo.refresh() called', () async {
      buildViewModel(songs: [makeSong('s1')]);
      await settle();

      verify(() => repo.refresh()).called(greaterThanOrEqualTo(1));
    });

    test('failure when song loader fails: status failure', () async {
      final vm = AddToPlaylistViewModel(
        repository: repo,
        songLoader: () async => Result.error(Exception('offline')),
      );
      await settle();

      expect(vm.status, FetchStatus.failure);
    });

    test('failure when getPlaylists fails: status failure', () async {
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.error(Exception('db fail')));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      expect(vm.status, FetchStatus.failure);
    });
  });

  group('toggleSelection', () {
    test('adds then removes playlist and notifies', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      final vm = buildViewModel();
      await settle();

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.selectedPlaylists.length));

      vm.toggleSelection(pl);
      vm.toggleSelection(pl);

      expect(seen, [1, 0]);
      expect(vm.selectedPlaylists, isEmpty);
    });
  });

  group('search', () {
    test('empty search shows all and notifies', () async {
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer(
        (_) async =>
            Result.ok([makePlaylist('1', name: 'Rock'), makePlaylist('2', name: 'Jazz')]),
      );
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);
      vm.search('');

      expect(vm.playlists.length, 2);
      expect(notified, isTrue);
    });

    test('filters case-insensitively and trims whitespace', () async {
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', name: 'Rock Mix'),
          makePlaylist('2', name: 'Jazz Vibes'),
        ]),
      );
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);
      vm.search('  ROCK  ');

      expect(vm.playlists.length, 1);
      expect(vm.playlists.first.name, 'Rock Mix');
      expect(notified, isTrue);
    });
  });

  group('addSongsToPlaylists single-song', () {
    test('adds to each selected playlist and counts successes', () async {
      final pl1 = makePlaylist('pl-1');
      final pl2 = makePlaylist('pl-2');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl1, pl2]));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      vm.toggleSelection(pl1);
      vm.toggleSelection(pl2);

      final count = await vm.addSongsToPlaylists((p, s) async => true);

      expect(count, 2);
      verify(() => repo.addTracks('pl-1', any())).called(1);
      verify(() => repo.addTracks('pl-2', any())).called(1);
    });

    test('addTracks Err on one playlist: that one skipped, others continue', () async {
      final pl1 = makePlaylist('pl-1');
      final pl2 = makePlaylist('pl-2');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl1, pl2]));
      when(() => repo.addTracks('pl-1', any()))
          .thenAnswer((_) async => Result.error(Exception('fail')));
      when(() => repo.addTracks('pl-2', any()))
          .thenAnswer((_) async => const Result.ok(null));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      vm.toggleSelection(pl1);
      vm.toggleSelection(pl2);

      final count = await vm.addSongsToPlaylists((p, s) async => true);

      expect(count, 1);
    });
  });

  group('addSongsToPlaylists multi-song', () {
    test('no duplicates: all songs added', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(<String>{}));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      vm.toggleSelection(pl);

      final count = await vm.addSongsToPlaylists((p, s) async => true);

      expect(count, 1);
      verify(() => repo.addTracks('pl-1', any())).called(1);
    });

    test('duplicate, askDuplicate → true: song included', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok({'s1'}));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      vm.toggleSelection(pl);

      final count = await vm.addSongsToPlaylists((p, s) async => true);

      expect(count, 1);
      verify(() => repo.addTracks('pl-1', any())).called(1);
    });

    test('askDuplicate -> false: that song excluded, non-dup songs added', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok({'s1'}));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      vm.toggleSelection(pl);

      final count =
          await vm.addSongsToPlaylists((p, s) async => s.id == 's1' ? false : true);

      expect(count, 1);
      final captured =
          verify(() => repo.addTracks('pl-1', captureAny())).captured.single
              as Iterable;
      final ids = captured.map((s) => (s as Song).id).toList();
      expect(ids, contains('s2'));
      expect(ids, isNot(contains('s1')));
    });

    test('askDuplicate -> null: entire playlist skipped, not counted', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => Result.ok({'s1'}));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      vm.toggleSelection(pl);

      final count = await vm.addSongsToPlaylists((p, s) async => null);

      expect(count, 0);
      verifyNever(() => repo.addTracks(any(), any()));
    });

    test('empty add set (all skipped via false): no addTracks but playlist counted',
        () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => Result.ok({'s1', 's2'}));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      vm.toggleSelection(pl);

      final count = await vm.addSongsToPlaylists((p, s) async => false);

      expect(count, 1);
      verifyNever(() => repo.addTracks(any(), any()));
    });

    test('getTrackIdsInPlaylist Err: playlist skipped, not counted', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getTrackIdsInPlaylist('pl-1'))
          .thenAnswer((_) async => Result.error(Exception('fail')));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      vm.toggleSelection(pl);

      final count = await vm.addSongsToPlaylists((p, s) async => true);

      expect(count, 0);
      verifyNever(() => repo.addTracks(any(), any()));
    });
  });

  group('removeSongFromPlaylist', () {
    test('single-song: decrements count and notifies', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getCountOfSongInPlaylists('s1'))
          .thenAnswer((_) async => Result.ok({'pl-1': 2}));

      final vm = buildViewModel(songs: [makeSong('s1')]);
      await settle();

      final seen = <int?>[];
      vm.addListener(() => seen.add(vm.songInPlaylistCounts['pl-1']));

      await vm.removeSongFromPlaylist(pl);

      expect(seen, contains(1));
      verify(() => repo.removeLastOccurrenceOfTrack('pl-1', 's1')).called(1);
    });

    test('multi-song mode: no-op', () async {
      final pl = makePlaylist('pl-1');
      when(
        () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
      ).thenAnswer((_) async => Result.ok([pl]));

      final vm = buildViewModel(songs: [makeSong('s1'), makeSong('s2')]);
      await settle();

      await vm.removeSongFromPlaylist(pl);

      verifyNever(() => repo.removeLastOccurrenceOfTrack(any(), any()));
    });
  });

  test('_onPlaylistsChanged reloads playlists and refreshes counts', () async {
    final pl1 = makePlaylist('pl-1');
    when(
      () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
    ).thenAnswer((_) async => Result.ok([pl1]));

    final vm = buildViewModel();
    await settle();

    final repoListener =
        verify(() => repo.addListener(captureAny())).captured.last
            as void Function();

    final pl2 = makePlaylist('pl-2');
    when(
      () => repo.getPlaylists(orderBy: any(named: 'orderBy')),
    ).thenAnswer((_) async => Result.ok([pl1, pl2]));

    repoListener();
    await settle();

    expect(vm.playlists.length, 2);
  });
}