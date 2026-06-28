import 'dart:async';

import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/date.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/artist/artist_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

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

Album makeAlbum({
  String id = 'a',
  ReleaseType releaseType = ReleaseType.album,
  Date? originalDate,
  Date? releaseDate,
}) =>
    Album(
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
      version: null,
      musicBrainzId: null,
    );

Artist makeArtist({String id = 'art', List<Album>? albums}) => Artist(
      id: id,
      name: 'Artist $id',
      coverId: 'c',
      albums: albums,
      albumCount: albums?.length,
      genres: const [],
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FavoriteType.album);
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(makeAlbum());
    registerFallbackValue(makeArtist());
    registerFallbackValue((List<Song> _, bool _) async {});
  });

  late MockSubsonicRepository subsonic;
  late MockFavoritesRepository favorites;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;

  setUp(() {
    subsonic = MockSubsonicRepository();
    favorites = MockFavoritesRepository();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => queue.replace(any(), any())).thenAnswer((_) async {});
    when(() => queue.addAll(any(), any())).thenAnswer((_) async {});
    when(() => favorites.isFavorite(any(), any())).thenReturn(false);

    when(() => subsonic.getArtistInfo(any()))
        .thenAnswer((_) async => Result.ok(ArtistInfo(description: null)));
    when(() => subsonic.getAppearsOn(any()))
        .thenAnswer((_) async => const Result.ok([]));
  });

  ArtistViewModel buildViewModel() => ArtistViewModel(
        subsonicRepository: subsonic,
        favoritesRepository: favorites,
        playbackManager: playback,
      );

  Future<void> settle() => Future.delayed(Duration.zero);

  // Stubs incrementallyLoadSongs to capture the albums/shuffle flags passed and
  // to drive the per-batch callback once for each entry in firstBatchFlags.
  void stubIncrementalLoad({
    required List<Song> songs,
    required List<bool> firstBatchFlags,
    void Function(List<String> albumIds)? captureAlbumIds,
    void Function(bool? shuffleAlbums, bool? shuffleSongs)? captureShuffle,
    Result<void> result = const Result.ok(null),
  }) {
    when(
      () => subsonic.incrementallyLoadSongs(
        any(),
        any(),
        shuffleAlbums: any(named: 'shuffleAlbums'),
        shuffleSongs: any(named: 'shuffleSongs'),
      ),
    ).thenAnswer((invocation) async {
      captureAlbumIds?.call(
        (invocation.positionalArguments[0] as Iterable<Album>)
            .map((a) => a.id)
            .toList(),
      );
      captureShuffle?.call(
        invocation.namedArguments[#shuffleAlbums] as bool?,
        invocation.namedArguments[#shuffleSongs] as bool?,
      );
      final cb = invocation.positionalArguments[1]
          as Future<void> Function(List<Song>, bool);
      for (final firstBatch in firstBatchFlags) {
        await cb(songs, firstBatch);
      }
      return result;
    });
  }

  group('load', () {
    test('reports failure when getArtist fails', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.load('art');

      expect(vm.status, FetchStatus.failure);
      expect(vm.artist, isNull);
      expect(notified, isTrue);
    });

    test('transitions through loading then success', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.status));

      await vm.load('art');
      await settle();

      expect(statuses, containsAllInOrder([FetchStatus.loading, FetchStatus.success]));
      expect(vm.artist, isNotNull);
    });

    test('clears previously loaded artist while reloading', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      final vm = buildViewModel();
      await vm.load('art');
      await settle();
      expect(vm.artist, isNotNull);

      final artistDuringLoad = <Artist?>[];
      vm.addListener(() {
        if (vm.status == FetchStatus.loading) artistDuringLoad.add(vm.artist);
      });

      await vm.load('art');
      await settle();

      expect(artistDuringLoad, isNotEmpty);
      expect(artistDuringLoad.every((a) => a == null), isTrue);
    });

    test('sorts releases by type order then originalDate desc then releaseDate desc',
        () async {
      final albums = [
        makeAlbum(
          id: 'ep-2021',
          releaseType: ReleaseType.ep,
          originalDate: Date(year: 2021),
        ),
        makeAlbum(
          id: 'album-2023',
          releaseType: ReleaseType.album,
          originalDate: Date(year: 2023),
        ),
        makeAlbum(
          id: 'single-null',
          releaseType: ReleaseType.single,
        ),
        makeAlbum(
          id: 'album-2020',
          releaseType: ReleaseType.album,
          originalDate: Date(year: 2020),
        ),
        makeAlbum(
          id: 'album-2020-rd',
          releaseType: ReleaseType.album,
          originalDate: Date(year: 2020),
          releaseDate: Date(year: 2021),
        ),
      ];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));
      final vm = buildViewModel();

      await vm.load('art');
      await settle();

      final ids = vm.artist!.albums!.map((a) => a.id).toList();
      expect(ids[0], 'album-2023');
      expect(ids[1], 'album-2020-rd');
      expect(ids[2], 'album-2020');
      expect(ids[3], 'ep-2021');
      expect(ids[4], 'single-null');
    });
  });

  group('_getAlbumsByReleaseType early exit', () {
    test('returns only the contiguous group and stops at the next type',
        () async {
      // After sorting: albums (order 0) come first, then EPs (order 1), then
      // singles (order 4). Querying for EP type should return only the two EPs
      // and not the trailing single.
      final albums = [
        makeAlbum(id: 'album-a', releaseType: ReleaseType.album),
        makeAlbum(id: 'ep-b', releaseType: ReleaseType.ep),
        makeAlbum(id: 'ep-c', releaseType: ReleaseType.ep),
        makeAlbum(id: 'single-d', releaseType: ReleaseType.single),
      ];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));

      List<String>? capturedAlbumIds;
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final passedAlbums =
            invocation.positionalArguments[0] as Iterable<Album>;
        capturedAlbumIds = passedAlbums.map((a) => a.id).toList();
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.playReleases(ReleaseType.ep);

      expect(capturedAlbumIds, ['ep-b', 'ep-c']);
    });
  });

  group('playReleases', () {
    test('first batch: calls playOnNextMediaChange and queue.replace', () async {
      final albums = [makeAlbum(id: 'a1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));

      final songs = [makeSong('s1'), makeSong('s2')];
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, true);
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      final result = await vm.playReleases(ReleaseType.album);

      expect(result, isA<Ok>());
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 0)).called(1);
      verifyNever(() => queue.addAll(any(), any()));
    });

    test('later batches: calls queue.addAll with false', () async {
      final albums = [makeAlbum(id: 'a1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));

      final songs = [makeSong('s1')];
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, false);
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.playReleases(ReleaseType.album);

      verify(() => queue.addAll(songs, false)).called(1);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });
  });

  group('addReleasesToQueue', () {
    test('callback always calls queue.addAll with given priority, never replace',
        () async {
      final albums = [makeAlbum(id: 'a1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));

      final songs = [makeSong('s1')];
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, true);
        await cb(songs, false);
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.addReleasesToQueue(ReleaseType.album, true);

      verify(() => queue.addAll(songs, true)).called(2);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });
  });

  group('play() with albums == null', () {
    test('uses _appearsOn list when artist.albums is null', () async {
      final appearsOnAlbums = [makeAlbum(id: 'ao1')];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: null)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok(appearsOnAlbums));

      List<String>? capturedAlbumIds;
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final passedAlbums =
            invocation.positionalArguments[0] as Iterable<Album>;
        capturedAlbumIds = passedAlbums.map((a) => a.id).toList();
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.play();

      expect(capturedAlbumIds, ['ao1']);
    });
  });

  group('addToQueue() with albums == null', () {
    test('uses _appearsOn list when artist.albums is null', () async {
      final appearsOnAlbums = [makeAlbum(id: 'ao1')];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: null)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok(appearsOnAlbums));

      List<String>? capturedAlbumIds;
      when(
        () => subsonic.incrementallyLoadSongs(
          any(),
          any(),
          shuffleAlbums: any(named: 'shuffleAlbums'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final passedAlbums =
            invocation.positionalArguments[0] as Iterable<Album>;
        capturedAlbumIds = passedAlbums.map((a) => a.id).toList();
        return const Result.ok(null);
      });

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.addToQueue(false);

      expect(capturedAlbumIds, ['ao1']);
    });
  });

  group('toggleFavorite', () {
    setUp(() {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
    });

    test('optimistic success: marks favorite true and calls setFavorite',
        () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      expect(vm.favorite, isTrue);
      verify(() => favorites.setFavorite(FavoriteType.artist, 'art', true))
          .called(1);
    });

    test('rolls back on error: seen sequence is [true, false]', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => Result.error(Exception('offline')));
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      final result = await vm.toggleFavorite();

      expect(result, isA<Err>());
      expect(vm.favorite, isFalse);
      expect(seen, [true, false]);
    });
  });

  group('external favorites listener', () {
    test('updates favorite when repository notifies', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      final vm = buildViewModel();
      final listener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();
      await vm.load('art');
      await settle();

      when(() => favorites.isFavorite(FavoriteType.artist, 'art'))
          .thenReturn(true);
      listener();

      expect(vm.favorite, isTrue);
    });

    test('is no-op before load (_artistId == null)', () {
      final vm = buildViewModel();
      final listener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();

      var notified = false;
      vm.addListener(() => notified = true);

      listener();

      expect(notified, isFalse);
    });
  });

  group('_loadDescription', () {
    test('Err sets description to empty string and notifies', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getArtistInfo(any()))
          .thenAnswer((_) async => Result.error(Exception('info fail')));
      final vm = buildViewModel();
      await vm.load('art');

      final descriptions = <String?>[];
      vm.addListener(() => descriptions.add(vm.description));

      await settle();

      expect(vm.description, '');
      expect(descriptions, contains(''));
    });

    test('Ok(null description) sets description to empty string', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getArtistInfo(any()))
          .thenAnswer((_) async => Result.ok(ArtistInfo(description: null)));
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      expect(vm.description, '');
    });

    test('Ok(description) sets description to the returned value', () async {
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getArtistInfo(any())).thenAnswer(
        (_) async =>
            Result.ok(ArtistInfo(description: 'Biography text')),
      );
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      expect(vm.description, 'Biography text');
    });
  });

  group('_loadAppearsOn', () {
    // getAppearsOn is driven by a completer so the listener can be attached
    // after the synchronous clear-to-empty (which happens inside load, before
    // the test regains control) but before the async result arrives. This
    // isolates the post-load notification from the unrelated description notify.
    test('Err: result does not notify', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) => completer.future);
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);
      completer.complete(Result.error(Exception('nope')));
      await settle();

      expect(vm.appearsOn, isEmpty);
      expect(notified, isFalse);
    });

    test('Ok([]): empty result does not notify', () async {
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) => completer.future);
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);
      completer.complete(const Result.ok([]));
      await settle();

      expect(vm.appearsOn, isEmpty);
      expect(notified, isFalse);
    });

    test('Ok([album]): populates appearsOn and notifies', () async {
      final album = makeAlbum(id: 'ao1');
      final completer = Completer<Result<Iterable<Album>>>();
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: [])));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) => completer.future);
      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      var notified = false;
      vm.addListener(() => notified = true);
      completer.complete(Result.ok([album]));
      await settle();

      expect(vm.appearsOn.map((a) => a.id), ['ao1']);
      expect(notified, isTrue);
    });
  });

  group('playAppearsOn', () {
    test('plays the appearsOn albums (first batch replaces)', () async {
      final albums = [makeAlbum(id: 'ao1')];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: null)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok(albums));

      final songs = [makeSong('s1')];
      List<String>? capturedAlbumIds;
      stubIncrementalLoad(
        songs: songs,
        firstBatchFlags: [true],
        captureAlbumIds: (ids) => capturedAlbumIds = ids,
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      final result = await vm.playAppearsOn();

      expect(result, isA<Ok>());
      expect(capturedAlbumIds, ['ao1']);
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 0)).called(1);
    });
  });

  group('addAppearsOnToQueue', () {
    test('adds appearsOn albums to queue with given priority', () async {
      final albums = [makeAlbum(id: 'ao1')];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: null)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok(albums));

      final songs = [makeSong('s1')];
      List<String>? capturedAlbumIds;
      stubIncrementalLoad(
        songs: songs,
        firstBatchFlags: [true, false],
        captureAlbumIds: (ids) => capturedAlbumIds = ids,
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.addAppearsOnToQueue(true);

      expect(capturedAlbumIds, ['ao1']);
      verify(() => queue.addAll(songs, true)).called(2);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });
  });

  group('play()/addToQueue() with albums present', () {
    test('play() uses artist.albums, not appearsOn', () async {
      final albums = [makeAlbum(id: 'al1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok([makeAlbum(id: 'ao1')]));

      final songs = [makeSong('s1')];
      List<String>? capturedAlbumIds;
      stubIncrementalLoad(
        songs: songs,
        firstBatchFlags: [true],
        captureAlbumIds: (ids) => capturedAlbumIds = ids,
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.play();

      expect(capturedAlbumIds, ['al1']);
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 0)).called(1);
    });

    test('addToQueue() uses artist.albums, not appearsOn', () async {
      final albums = [makeAlbum(id: 'al1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));
      when(() => subsonic.getAppearsOn(any()))
          .thenAnswer((_) async => Result.ok([makeAlbum(id: 'ao1')]));

      final songs = [makeSong('s1')];
      List<String>? capturedAlbumIds;
      stubIncrementalLoad(
        songs: songs,
        firstBatchFlags: [false],
        captureAlbumIds: (ids) => capturedAlbumIds = ids,
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.addToQueue(true);

      expect(capturedAlbumIds, ['al1']);
      verify(() => queue.addAll(songs, true)).called(1);
      verifyNever(() => queue.replace(any(), any()));
    });
  });

  group('_queueAlbums shuffle + error propagation', () {
    test('forwards shuffle flags to incrementallyLoadSongs', () async {
      final albums = [makeAlbum(id: 'a1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));

      bool? capturedShuffleAlbums;
      bool? capturedShuffleSongs;
      stubIncrementalLoad(
        songs: [makeSong('s1')],
        firstBatchFlags: const [],
        captureShuffle: (sa, ss) {
          capturedShuffleAlbums = sa;
          capturedShuffleSongs = ss;
        },
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      await vm.playReleases(
        ReleaseType.album,
        shuffleReleases: true,
        shuffleSongs: true,
      );

      expect(capturedShuffleAlbums, isTrue);
      expect(capturedShuffleSongs, isTrue);
    });

    test('propagates Err from incrementallyLoadSongs', () async {
      final albums = [makeAlbum(id: 'a1', releaseType: ReleaseType.album)];
      when(() => subsonic.getArtist(any()))
          .thenAnswer((_) async => Result.ok(makeArtist(albums: albums)));
      stubIncrementalLoad(
        songs: const [],
        firstBatchFlags: const [],
        result: Result.error(Exception('load fail')),
      );

      final vm = buildViewModel();
      await vm.load('art');
      await settle();

      final result = await vm.playReleases(ReleaseType.album);

      expect(result, isA<Err>());
    });
  });

  group('dispose', () {
    test('removes the favorites listener', () {
      final vm = buildViewModel();
      final listener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();

      vm.dispose();

      verify(() => favorites.removeListener(listener)).called(1);
    });
  });

  group('getArtistSongs', () {
    test('flattens nested lists on success', () async {
      final s1 = makeSong('s1');
      final s2 = makeSong('s2');
      final s3 = makeSong('s3');
      when(() => subsonic.getArtistSongs(any())).thenAnswer(
        (_) async => Result.ok([
          [s1, s2],
          [s3],
        ]),
      );
      final vm = buildViewModel();
      final artist = makeArtist();

      final result = await vm.getArtistSongs(artist);

      expect(result, isA<Ok>());
      expect((result as Ok).value, [s1, s2, s3]);
    });

    test('propagates error', () async {
      when(() => subsonic.getArtistSongs(any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel();

      final result = await vm.getArtistSongs(makeArtist());

      expect(result, isA<Err>());
    });
  });
}