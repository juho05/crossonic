import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/playlists/playlists_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaylistRepository extends Mock implements PlaylistRepository {}

class MockSongDownloader extends Mock implements SongDownloader {}

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

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

Playlist makePlaylist(
  String id, {
  String name = 'Playlist',
  bool download = false,
  int songCount = 0,
  Duration duration = Duration.zero,
  DateTime? created,
  DateTime? changed,
}) =>
    Playlist(
      id: id,
      name: name,
      comment: null,
      songCount: songCount,
      duration: duration,
      created: created ?? DateTime(2024, 1, 1),
      changed: changed ?? DateTime(2024, 1, 2),
      coverId: null,
      download: download,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (call) async {
        if (call.method == 'check') return <String>['wifi'];
        return null;
      },
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (args, sink) {}),
    );
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(<String>{});
  });

  late MockPlaylistRepository repo;
  late MockSongDownloader downloader;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;

  setUp(() {
    repo = MockPlaylistRepository();
    downloader = MockSongDownloader();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => queue.replace(any())).thenAnswer((_) async {});
    when(() => queue.replace(any(), any())).thenAnswer((_) async {});
    when(() => queue.addAll(any(), any())).thenAnswer((_) async {});

    when(() => repo.getPlaylists()).thenAnswer((_) async => const Result.ok([]));
    when(() => repo.getPlaylist(any())).thenAnswer((_) async => const Result.ok(null));
    when(
      () => repo.refresh(
        forceRefresh: any(named: 'forceRefresh'),
        refreshIds: any(named: 'refreshIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.setDownload(any(), any())).thenAnswer((_) async => const Result.ok(null));
    when(() => downloader.isDownloaded(any())).thenReturn(false);
  });

  PlaylistsViewModel buildViewModel() => PlaylistsViewModel(
        playlistRepository: repo,
        playbackManager: playback,
        songDownloader: downloader,
      );

  Future<void> settle() async {
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
  }

  group('sort setter', () {
    test('updated -> descending by default, re-filters, notifies', () async {
      final vm = buildViewModel();
      await settle();
      vm.sort = PlaylistsSort.alphabetical;

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.sortAscending));

      vm.sort = PlaylistsSort.updated;

      expect(vm.sortAscending, isFalse);
      expect(seen, isNotEmpty);
    });

    test('alphabetical -> ascending by default', () async {
      final vm = buildViewModel();
      await settle();
      vm.sort = PlaylistsSort.updated;

      vm.sort = PlaylistsSort.alphabetical;

      expect(vm.sortAscending, isTrue);
    });

    test('random does not change sortAscending', () async {
      final vm = buildViewModel();
      await settle();
      vm.sort = PlaylistsSort.alphabetical;
      expect(vm.sortAscending, isTrue);

      vm.sort = PlaylistsSort.random;

      expect(vm.sortAscending, isTrue);
    });

    test('songCount and duration default to descending', () async {
      final vm = buildViewModel();
      await settle();

      vm.sort = PlaylistsSort.alphabetical;
      vm.sort = PlaylistsSort.songCount;
      expect(vm.sortAscending, isFalse);

      vm.sort = PlaylistsSort.alphabetical;
      vm.sort = PlaylistsSort.duration;
      expect(vm.sortAscending, isFalse);
    });

    test('created defaults to descending', () async {
      final vm = buildViewModel();
      await settle();
      vm.sort = PlaylistsSort.alphabetical;

      vm.sort = PlaylistsSort.created;

      expect(vm.sortAscending, isFalse);
    });

    test('same sort value: no-op', () async {
      final vm = buildViewModel();
      await settle();
      vm.sort = PlaylistsSort.alphabetical;

      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.sort = PlaylistsSort.alphabetical;

      expect(notifyCount, 0);
    });
  });

  group('_comparePlaylists alphabetical', () {
    test('ascending: a before z', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([makePlaylist('1', name: 'Zebra'), makePlaylist('2', name: 'Apple')]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.alphabetical;

      expect(vm.playlists.map((p) => p.$1.name).toList(), ['Apple', 'Zebra']);
    });

    test('case-insensitive: lowercase not sorted after uppercase', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([makePlaylist('1', name: 'apple'), makePlaylist('2', name: 'Banana')]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.alphabetical;

      expect(vm.playlists.map((p) => p.$1.name).toList(), ['apple', 'Banana']);
    });

    test('descending: z before a', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([makePlaylist('1', name: 'Apple'), makePlaylist('2', name: 'Zebra')]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.alphabetical;
      vm.sortAscending = false;

      expect(vm.playlists.map((p) => p.$1.name).toList(), ['Zebra', 'Apple']);
    });
  });

  group('_comparePlaylists by field (desc default)', () {
    test('songCount descending: higher count first', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', songCount: 5),
          makePlaylist('2', songCount: 10),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.songCount;

      expect(vm.playlists.map((p) => p.$1.songCount).toList(), [10, 5]);
    });

    test('duration descending: longer first', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', duration: const Duration(seconds: 30)),
          makePlaylist('2', duration: const Duration(seconds: 60)),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.duration;

      expect(vm.playlists.map((p) => p.$1.duration.inSeconds).toList(), [60, 30]);
    });

    test('created descending: newer first', () async {
      final older = DateTime(2023, 1, 1);
      final newer = DateTime(2024, 1, 1);
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', created: older),
          makePlaylist('2', created: newer),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.created;

      expect(vm.playlists.first.$1.id, '2');
    });

    test('updated descending: more recently changed first', () async {
      final older = DateTime(2023, 6, 1);
      final newer = DateTime(2024, 6, 1);
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', changed: older),
          makePlaylist('2', changed: newer),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.sort = PlaylistsSort.updated;

      expect(vm.playlists.first.$1.id, '2');
    });
  });

  group('random sort', () {
    test('shuffles and notifies; result is set-equal to input', () async {
      final playlists = List.generate(10, (i) => makePlaylist('p$i', name: 'P$i'));
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok(playlists));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.playlists.length));

      vm.sort = PlaylistsSort.random;

      expect(seen, isNotEmpty);
      expect(
        vm.playlists.map((p) => p.$1.id).toSet(),
        equals(playlists.map((p) => p.id).toSet()),
      );
    });
  });

  group('search', () {
    test('empty search shows all', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', name: 'Rock'),
          makePlaylist('2', name: 'Jazz'),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.length, 2);
    });

    test('filters case-insensitively and notifies', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([
          makePlaylist('1', name: 'Rock Mix'),
          makePlaylist('2', name: 'Jazz Vibes'),
        ]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.playlists.length));

      vm.searchTerm = 'rock';

      expect(vm.playlists.length, 1);
      expect(vm.playlists.first.$1.name, 'Rock Mix');
      expect(seen, isNotEmpty);
    });

    test('same searchTerm: no-op', () async {
      final vm = buildViewModel();
      await settle();
      vm.searchTerm = 'test';

      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.searchTerm = 'test';

      expect(notifyCount, 0);
    });

    test('clearing search shows all again', () async {
      when(() => repo.getPlaylists()).thenAnswer(
        (_) async => Result.ok([makePlaylist('1'), makePlaylist('2')]),
      );
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      vm.searchTerm = 'filter-me';
      vm.searchTerm = '';

      expect(vm.playlists.length, 2);
    });
  });

  group('_load', () {
    test('Err -> empty playlists, notifies', () async {
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => Result.error(Exception('db fail')));
      final vm = buildViewModel();

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.playlists.length));

      await settle();

      expect(vm.playlists, isEmpty);
      expect(seen, contains(0));
    });

    test('Ok builds list and notifies; download=false -> DownloadStatus.none', () async {
      final pl = makePlaylist('pl-1', name: 'My Mix');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.length, 1);
      expect(vm.playlists.first.$1, pl);
      expect(vm.playlists.first.$2, DownloadStatus.none);
    });
  });

  group('_getPlaylistDownloadStatus', () {
    test('download=false -> none', () async {
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => Result.ok([makePlaylist('p1', download: false)]));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.first.$2, DownloadStatus.none);
    });

    test('download=true + getPlaylist Err -> downloading', () async {
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => Result.ok([makePlaylist('p1', download: true)]));
      when(() => repo.getPlaylist('p1'))
          .thenAnswer((_) async => Result.error(Exception('fail')));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.first.$2, DownloadStatus.downloading);
    });

    test('download=true + all downloaded -> downloaded', () async {
      final pl = makePlaylist('p1', download: true);
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
      );
      when(() => downloader.isDownloaded('s1')).thenReturn(true);
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.first.$2, DownloadStatus.downloaded);
    });

    test('download=true + partial -> downloading', () async {
      final pl = makePlaylist('p1', download: true);
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1'), makeSong('s2')])),
      );
      when(() => downloader.isDownloaded('s1')).thenReturn(true);
      when(() => downloader.isDownloaded('s2')).thenReturn(false);
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      expect(vm.playlists.first.$2, DownloadStatus.downloading);
    });
  });

  group('toggleDownload', () {
    test('Ok -> status becomes downloading, notifies', () async {
      final pl = makePlaylist('p1');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      final seen = <DownloadStatus>[];
      vm.addListener(() {
        if (vm.playlists.isNotEmpty) seen.add(vm.playlists.first.$2);
      });

      final result = await vm.toggleDownload(pl);

      expect(result, isA<Ok>());
      expect(seen, contains(DownloadStatus.downloading));
    });
  });

  group('offline setter', () {
    test('offline=true drops DownloadStatus.none items, notifies', () async {
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => Result.ok([makePlaylist('p1')]));
      final vm = buildViewModel();
      await settle();
      vm.offline = false;

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.playlists.length));

      vm.offline = true;

      expect(vm.playlists, isEmpty);
      expect(seen, contains(0));
    });

    test('offline=false shows all items, notifies', () async {
      when(() => repo.getPlaylists())
          .thenAnswer((_) async => Result.ok([makePlaylist('p1')]));
      final vm = buildViewModel();
      await settle();
      vm.offline = true;

      final seen = <int>[];
      vm.addListener(() => seen.add(vm.playlists.length));

      vm.offline = false;

      expect(vm.playlists.length, 1);
      expect(seen, contains(1));
    });
  });

  group('clearFilters', () {
    test('resets searchTerm to empty', () async {
      final vm = buildViewModel();
      await settle();
      vm.searchTerm = 'something';

      vm.clearFilters();

      expect(vm.searchTerm, isEmpty);
    });
  });

  group('_onDownloadStatusChanged', () {
    test('re-filters when status changed (fakeAsync 3s, leading=true)', () {
      fakeAsync((async) {
        final pl = makePlaylist('p1', download: true);
        when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
        when(() => repo.getPlaylist('p1')).thenAnswer(
          (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
        );
        when(() => downloader.isDownloaded('s1')).thenReturn(false);

        final vm = buildViewModel();
        async.flushMicrotasks();
        vm.offline = false;

        final downloaderListener =
            verify(() => downloader.addListener(captureAny())).captured.last
                as void Function();

        when(() => downloader.isDownloaded('s1')).thenReturn(true);

        var notified = false;
        vm.addListener(() => notified = true);

        downloaderListener();
        async.flushMicrotasks();

        expect(notified, isTrue);
        expect(vm.playlists.first.$2, DownloadStatus.downloaded);
      });
    });
  });

  group('play', () {
    test('without shuffle: calls playOnNextMediaChange and replace', () async {
      final pl = makePlaylist('p1');
      final song = makeSong('s1');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [song])),
      );
      final vm = buildViewModel();
      await settle();

      await vm.play(pl);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });

    test('playlist gone (getPlaylist Ok null): returns error, no playback', () async {
      final pl = makePlaylist('p1');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1'))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      final result = await vm.play(pl);

      expect(result, isA<Err>());
      verifyNever(() => player.playOnNextMediaChange());
      verifyNever(() => queue.replace(any()));
    });

    test('getPlaylist Err: returns error, no playback', () async {
      final pl = makePlaylist('p1');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1'))
          .thenAnswer((_) async => Result.error(Exception('fetch fail')));
      final vm = buildViewModel();
      await settle();

      final result = await vm.play(pl);

      expect(result, isA<Err>());
      verifyNever(() => player.playOnNextMediaChange());
      verifyNever(() => queue.replace(any()));
    });

    test('with shuffle: shuffles songs before replace', () async {
      final pl = makePlaylist('p1');
      final songs = List.generate(5, (i) => makeSong('s$i'));
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: songs)),
      );
      final vm = buildViewModel();
      await settle();

      await vm.play(pl, shuffle: true);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });
  });

  group('addToQueue', () {
    test('calls queue.addAll with tracks and priority', () async {
      final pl = makePlaylist('p1');
      when(() => repo.getPlaylists()).thenAnswer((_) async => Result.ok([pl]));
      when(() => repo.getPlaylist('p1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
      );
      final vm = buildViewModel();
      await settle();

      await vm.addToQueue(pl, true);

      verify(() => queue.addAll(any(), true)).called(1);
    });
  });
}