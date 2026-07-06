import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/playlist/models/playlist.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/playlist/playlist_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
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

Playlist makePlaylist({
  String id = 'pl-1',
  String name = 'My Playlist',
  bool download = false,
}) =>
    Playlist(
      id: id,
      name: name,
      comment: null,
      songCount: 0,
      duration: Duration.zero,
      created: DateTime(2024),
      changed: DateTime(2024),
      coverId: null,
      download: download,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(makePlaylist());
    registerFallbackValue(<String>{});
    registerFallbackValue(Uint8List(0));
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
    when(
      () => queue.clear(
        queue: any(named: 'queue'),
        fromIndex: any(named: 'fromIndex'),
        priorityQueue: any(named: 'priorityQueue'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.getPlaylist(any())).thenAnswer((_) async => const Result.ok(null));
    when(
      () => repo.refresh(
        forceRefresh: any(named: 'forceRefresh'),
        refreshIds: any(named: 'refreshIds'),
      ),
    ).thenAnswer((_) async {});
    when(() => repo.removeTrack(any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.reorder(any(), any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.delete(any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.setCover(any(), any(), any()))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.changeCoverSupported).thenReturn(false);
    when(() => downloader.getStatus(any())).thenReturn(DownloadStatus.none);
    when(() => downloader.isDownloaded(any())).thenReturn(false);
  });

  PlaylistViewModel buildViewModel([String id = 'pl-1']) => PlaylistViewModel(
        playlistRepository: repo,
        playbackManager: playback,
        songDownloader: downloader,
        playlistId: id,
      );

  Future<void> settle() async {
    await Future.delayed(Duration.zero);
    await Future.delayed(Duration.zero);
  }

  group('_load', () {
    test('Ok: tracks built with download statuses, notifies', () async {
      final s1 = makeSong('s1');
      final s2 = makeSong('s2');
      final pl = makePlaylist(download: true);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [s1, s2])),
      );
      when(() => downloader.getStatus('s1')).thenReturn(DownloadStatus.downloaded);
      when(() => downloader.getStatus('s2')).thenReturn(DownloadStatus.downloading);

      var notified = false;
      final vm = buildViewModel();
      vm.addListener(() => notified = true);
      await settle();

      expect(vm.tracks.length, 2);
      expect(vm.tracks[0].$2, DownloadStatus.downloaded);
      expect(vm.tracks[1].$2, DownloadStatus.downloading);
      expect(vm.downloadedTracks, 1);
      expect(vm.downloadStatus, DownloadStatus.downloading);
      expect(notified, isTrue);
    });

    test('all songs downloaded -> downloadStatus downloaded', () async {
      final pl = makePlaylist(download: true);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
      );
      when(() => downloader.getStatus('s1')).thenReturn(DownloadStatus.downloaded);

      final vm = buildViewModel();
      await settle();

      expect(vm.downloadStatus, DownloadStatus.downloaded);
      expect(vm.downloadedTracks, 1);
    });

    test('download=false -> downloadStatus none', () async {
      final pl = makePlaylist(download: false);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
      );

      final vm = buildViewModel();
      await settle();

      expect(vm.downloadStatus, DownloadStatus.none);
    });

    test('Err: playlist null, notifies', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => Result.error(Exception('fail')));

      var notified = false;
      final vm = buildViewModel();
      vm.addListener(() => notified = true);
      await settle();

      expect(vm.playlist, isNull);
      expect(notified, isTrue);
    });

    test('Ok(null): playlist null, notifies', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));

      var notified = false;
      final vm = buildViewModel();
      vm.addListener(() => notified = true);
      await settle();

      expect(vm.playlist, isNull);
      expect(notified, isTrue);
    });

    test('repo listener triggers reload', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      final repoListener =
          verify(() => repo.addListener(captureAny())).captured.last
              as void Function();

      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );

      repoListener();
      await settle();

      expect(vm.playlist, isNotNull);
    });
  });

  group('_deleted guard', () {
    test('_load short-circuits after delete', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      final vm = buildViewModel();
      await settle();

      final repoListener =
          verify(() => repo.addListener(captureAny())).captured.last
              as void Function();

      await vm.delete();

      verify(() => repo.getPlaylist('pl-1')).called(greaterThanOrEqualTo(1));
      clearInteractions(repo);

      repoListener();
      await settle();

      verifyNever(() => repo.getPlaylist(any()));
    });

    test('_onDownloadStatusChanged short-circuits after delete', () {
      fakeAsync((async) {
        final pl = makePlaylist(download: true);
        when(() => repo.getPlaylist('pl-1')).thenAnswer(
          (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
        );
        final vm = buildViewModel();
        async.flushMicrotasks();

        final downloaderListener =
            verify(() => downloader.addListener(captureAny())).captured.last
                as void Function();

        vm.delete();

        var notified = false;
        vm.addListener(() => notified = true);

        downloaderListener();
        async.elapse(const Duration(milliseconds: 250));

        expect(notified, isFalse);
      });
    });
  });

  group('_onDownloadStatusChanged', () {
    test('updates track status and notifies once on change (fakeAsync 250ms)', () {
      fakeAsync((async) {
        final s1 = makeSong('s1');
        final pl = makePlaylist(download: true);
        when(() => repo.getPlaylist('pl-1')).thenAnswer(
          (_) async => Result.ok((playlist: pl, tracks: [s1])),
        );
        when(() => downloader.getStatus('s1')).thenReturn(DownloadStatus.downloading);

        final vm = buildViewModel();
        async.flushMicrotasks();

        final downloaderListener =
            verify(() => downloader.addListener(captureAny())).captured.last
                as void Function();

        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        when(() => downloader.getStatus('s1')).thenReturn(DownloadStatus.downloaded);

        downloaderListener();
        expect(notifyCount, 0);

        async.elapse(const Duration(milliseconds: 250));

        expect(notifyCount, 1);
        expect(vm.tracks.first.$2, DownloadStatus.downloaded);
        expect(vm.downloadStatus, DownloadStatus.downloaded);
      });
    });

    test('no status change -> no notification', () {
      fakeAsync((async) {
        final s1 = makeSong('s1');
        final pl = makePlaylist(download: true);
        when(() => repo.getPlaylist('pl-1')).thenAnswer(
          (_) async => Result.ok((playlist: pl, tracks: [s1])),
        );
        when(() => downloader.getStatus('s1')).thenReturn(DownloadStatus.downloading);

        final vm = buildViewModel();
        async.flushMicrotasks();

        final downloaderListener =
            verify(() => downloader.addListener(captureAny())).captured.last
                as void Function();

        var notifyCount = 0;
        vm.addListener(() => notifyCount++);

        downloaderListener();
        async.elapse(const Duration(milliseconds: 250));

        expect(notifyCount, 0);
      });
    });
  });

  group('play', () {
    setUp(() {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1'), makeSong('s2')])),
      );
    });

    test('empty tracks -> clear queue', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      vm.play();

      verify(() => queue.clear(priorityQueue: false)).called(1);
      verifyNever(() => player.playOnNextMediaChange());
    });

    test('single=true -> replace with one track', () async {
      final vm = buildViewModel();
      await settle();

      vm.play(0, true);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
      verifyNever(() => queue.replace(any(), any()));
    });

    test('multi: replace from given index + playOnNextMediaChange', () async {
      final vm = buildViewModel();
      await settle();

      vm.play(1);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any(), 1)).called(1);
    });
  });

  group('shuffle', () {
    test('empty tracks -> clear queue', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      vm.shuffle();

      verify(() => queue.clear(priorityQueue: false)).called(1);
    });

    test('non-empty -> replace shuffled + playOnNextMediaChange', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((
          playlist: pl,
          tracks: List.generate(5, (i) => makeSong('s$i')),
        )),
      );
      final vm = buildViewModel();
      await settle();

      vm.shuffle();

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(any())).called(1);
    });
  });

  group('addToQueue', () {
    test('empty tracks: no-op', () async {
      when(() => repo.getPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      vm.addToQueue(true);

      verifyNever(() => queue.addAll(any(), any()));
    });

    test('non-empty: calls addAll with priority', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1')])),
      );
      final vm = buildViewModel();
      await settle();

      vm.addToQueue(true);

      verify(() => queue.addAll(any(), true)).called(1);
    });
  });

  group('remove', () {
    test('removes locally, notifies, then calls repo', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1'), makeSong('s2')])),
      );
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.remove(0);

      expect(vm.tracks.length, 1);
      expect(vm.tracks.first.$1.id, 's2');
      expect(notified, isTrue);
      verify(() => repo.removeTrack('pl-1', 0)).called(1);
    });
  });

  group('reorder', () {
    test('moves locally, notifies, then calls repo', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [makeSong('s1'), makeSong('s2')])),
      );
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.reorder(0, 1);

      expect(vm.tracks[0].$1.id, 's2');
      expect(notified, isTrue);
      verify(() => repo.reorder(any(), 0, 1)).called(1);
    });
  });

  group('delete', () {
    test('sets _deleted and calls repo.delete', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      final vm = buildViewModel();
      await settle();

      await vm.delete();

      verify(() => repo.delete('pl-1')).called(1);
    });
  });

  group('editMode', () {
    test('setter notifies', () async {
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);

      vm.editMode = true;

      expect(vm.editMode, isTrue);
      expect(notified, isTrue);
    });
  });

  group('removeCover', () {
    test('toggles uploadingCover true->false and calls setCover', () async {
      final pl = makePlaylist();
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      final vm = buildViewModel();
      await settle();

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.uploadingCover));

      await vm.removeCover();

      expect(seen, [true, false]);
      verify(() => repo.setCover('pl-1', '', any())).called(1);
    });
  });

  group('toggleDownload', () {
    test('enable: downloadStatus downloading, notifies, setDownload(true)', () async {
      final pl = makePlaylist(download: false);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      when(() => repo.setDownload('pl-1', any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);

      final result = await vm.toggleDownload();

      expect(result, isA<Ok>());
      expect(vm.downloadStatus, DownloadStatus.downloading);
      expect(notified, isTrue);
      verify(() => repo.setDownload('pl-1', true)).called(1);
    });

    test('disable: downloadStatus none, setDownload(false)', () async {
      final pl = makePlaylist(download: true);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      when(() => repo.setDownload('pl-1', any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await settle();

      await vm.toggleDownload();

      expect(vm.downloadStatus, DownloadStatus.none);
      verify(() => repo.setDownload('pl-1', false)).called(1);
    });

    test('Err: no state change, no notification', () async {
      final pl = makePlaylist(download: false);
      when(() => repo.getPlaylist('pl-1')).thenAnswer(
        (_) async => Result.ok((playlist: pl, tracks: [])),
      );
      when(() => repo.setDownload('pl-1', any()))
          .thenAnswer((_) async => Result.error(Exception('fail')));
      final vm = buildViewModel();
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);

      final result = await vm.toggleDownload();

      expect(result, isA<Err>());
      expect(vm.downloadStatus, DownloadStatus.none);
      expect(notified, isFalse);
    });
  });
}