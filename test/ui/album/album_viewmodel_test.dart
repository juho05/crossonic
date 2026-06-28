import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/album_info.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/album/album_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

class MockServerSupport extends Mock implements ServerSupport {}

Song makeSong(String id, {int? discNr, int? trackNr}) => Song(
      id: id,
      coverId: 'cover-$id',
      title: 'Song $id',
      displayArtist: 'Artist',
      artists: const [],
      album: null,
      genres: const [],
      duration: null,
      bpm: null,
      trackNr: trackNr,
      discNr: discNr,
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
  String id = 'album-1',
  required List<Song> songs,
  Map<int, String> discTitles = const {},
}) =>
    Album(
      id: id,
      name: 'Album',
      coverId: 'cover',
      releaseDate: null,
      originalDate: null,
      songs: songs,
      songCount: songs.length,
      displayArtist: 'Artist',
      artists: const [],
      discTitles: discTitles,
      releaseType: ReleaseType.album,
      version: null,
      musicBrainzId: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FavoriteType.album);
    registerFallbackValue(const <Song>[]);
  });

  late MockSubsonicRepository subsonic;
  late MockFavoritesRepository favorites;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;
  late MockServerSupport supports;

  setUp(() {
    subsonic = MockSubsonicRepository();
    favorites = MockFavoritesRepository();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();
    supports = MockServerSupport();

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => queue.replace(any(), any())).thenAnswer((_) async {});
    when(() => queue.addAll(any(), any())).thenAnswer((_) async {});
    when(() => queue.clear(priorityQueue: any(named: 'priorityQueue')))
        .thenAnswer((_) async {});

    when(() => favorites.isFavorite(any(), any())).thenReturn(false);

    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.getAlternateAlbumVersions).thenReturn(false);
    when(() => subsonic.getAlbumInfo(any()))
        .thenAnswer((_) async => Result.ok(AlbumInfo(description: '')));
  });

  AlbumViewModel buildViewModel() => AlbumViewModel(
        favoritesRepository: favorites,
        subsonicRepository: subsonic,
        playbackManager: playback,
      );

  // Lets the un-awaited _loadDescription / _loadAlternatives futures settle.
  Future<void> settle() => Future.delayed(Duration.zero);

  group('load', () {
    test('reports failure when the album cannot be fetched', () async {
      when(() => subsonic.getAlbum(any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel();

      await vm.load('album-1');

      expect(vm.status, FetchStatus.failure);
    });

    test('lays out a single-disc album as a flat song list', () async {
      final songs = [makeSong('a'), makeSong('b'), makeSong('c')];
      when(() => subsonic.getAlbum(any()))
          .thenAnswer((_) async => Result.ok(makeAlbum(songs: songs)));
      final vm = buildViewModel();

      await vm.load('album-1');
      await settle();

      expect(vm.status, FetchStatus.success);
      expect(vm.listItems.length, songs.length);
      for (var i = 0; i < songs.length; i++) {
        final (disc, song) = vm.listItems[i];
        expect(disc, isNull);
        expect(song!.$1, same(songs[i]));
        expect(song.$2, i);
      }
    });

    test('inserts disc headers for a multi-disc album', () async {
      final songs = [
        makeSong('a', discNr: 1),
        makeSong('b', discNr: 1),
        makeSong('c', discNr: 2),
        makeSong('d', discNr: 2),
      ];
      when(() => subsonic.getAlbum(any())).thenAnswer(
        (_) async => Result.ok(
          makeAlbum(songs: songs, discTitles: {1: 'Disc One', 2: 'Disc Two'}),
        ),
      );
      final vm = buildViewModel();

      await vm.load('album-1');
      await settle();

      final discHeaders =
          vm.listItems.where((i) => i.$1 != null).map((i) => i.$1).toList();
      expect(discHeaders, [1, 2]);

      final songEntries = vm.listItems
          .where((i) => i.$2 != null)
          .map((i) => i.$2!.$1.id)
          .toList();
      expect(songEntries, ['a', 'b', 'c', 'd']);
      expect(vm.listItems.length, songs.length + 2);
      expect(vm.discTitles, {1: 'Disc One', 2: 'Disc Two'});
    });

    test('inserts a disc header for a single named disc', () async {
      final songs = [makeSong('a', discNr: 1), makeSong('b', discNr: 1)];
      when(() => subsonic.getAlbum(any())).thenAnswer(
        (_) async => Result.ok(
          makeAlbum(songs: songs, discTitles: {1: 'The Only Disc'}),
        ),
      );
      final vm = buildViewModel();

      await vm.load('album-1');
      await settle();

      final discHeaders =
          vm.listItems.where((i) => i.$1 != null).map((i) => i.$1).toList();
      expect(discHeaders, [1]);

      final songEntries = vm.listItems
          .where((i) => i.$2 != null)
          .map((i) => i.$2!.$1.id)
          .toList();
      expect(songEntries, ['a', 'b']);
      expect(vm.listItems.length, songs.length + 1);
      expect(vm.discTitles, {1: 'The Only Disc'});
    });
  });

  group('toggleFavorite', () {
    setUp(() {
      when(() => subsonic.getAlbum(any())).thenAnswer(
        (_) async => Result.ok(makeAlbum(songs: [makeSong('a')])),
      );
    });

    test('optimistically marks favorite and persists the change', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await vm.load('album-1');
      await settle();
      expect(vm.favorite, isFalse);

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      expect(vm.favorite, isTrue);
      verify(() => favorites.setFavorite(FavoriteType.album, 'album-1', true))
          .called(1);
    });

    test('rolls back the optimistic change when persisting fails', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => Result.error(Exception('offline')));
      final vm = buildViewModel();
      await vm.load('album-1');
      await settle();

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      final result = await vm.toggleFavorite();

      expect(result, isA<Err>());
      expect(vm.favorite, isFalse, reason: 'rolled back to original state');
      expect(seen, contains(true),
          reason: 'briefly showed the optimistic favorite state');
    });
  });

  test('reflects external favorite changes from the repository', () async {
    when(() => subsonic.getAlbum(any())).thenAnswer(
      (_) async => Result.ok(makeAlbum(songs: [makeSong('a')])),
    );
    final vm = buildViewModel();
    final listener =
        verify(() => favorites.addListener(captureAny())).captured.single
            as void Function();
    await vm.load('album-1');
    await settle();
    expect(vm.favorite, isFalse);

    when(() => favorites.isFavorite(FavoriteType.album, 'album-1'))
        .thenReturn(true);
    listener();

    expect(vm.favorite, isTrue);
  });

  group('play', () {
    test('replaces the queue with all songs from the given index', () async {
      final songs = [makeSong('a'), makeSong('b'), makeSong('c')];
      when(() => subsonic.getAlbum(any()))
          .thenAnswer((_) async => Result.ok(makeAlbum(songs: songs)));
      final vm = buildViewModel();
      await vm.load('album-1');
      await settle();

      vm.play(1);

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 1)).called(1);
    });

    test('clears the queue when the album has no songs', () async {
      when(() => subsonic.getAlbum(any()))
          .thenAnswer((_) async => Result.ok(makeAlbum(songs: [])));
      final vm = buildViewModel();
      await vm.load('album-1');
      await settle();

      vm.play();

      verify(() => queue.clear(priorityQueue: false)).called(1);
      verifyNever(() => player.playOnNextMediaChange());
    });
  });
}
