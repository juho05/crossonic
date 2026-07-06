import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/common/artist_list_item_viewmodel.dart';
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

Album makeAlbum({String id = 'a'}) => Album(
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
  });

  ArtistListItemViewModel buildViewModel({Artist? artist}) =>
      ArtistListItemViewModel(
        favoritesRepository: favorites,
        subsonicRepository: subsonic,
        playbackManager: playback,
        artist: artist ?? makeArtist(),
      );

  group('construction', () {
    test('reads initial favorite state from repository', () {
      when(() => favorites.isFavorite(FavoriteType.artist, 'art'))
          .thenReturn(true);
      final vm = buildViewModel();

      expect(vm.favorite, isTrue);
    });

    test('starts with favorite == false when repository returns false', () {
      final vm = buildViewModel();

      expect(vm.favorite, isFalse);
    });
  });

  group('toggleFavorite', () {
    test('optimistically marks favorite and persists', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      expect(vm.favorite, isTrue);
      expect(seen, [true]);
      verify(() => favorites.setFavorite(FavoriteType.artist, 'art', true))
          .called(1);
    });

    test('rolls back when persisting fails', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => Result.error(Exception('offline')));
      final vm = buildViewModel();
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.favorite));

      final result = await vm.toggleFavorite();

      expect(result, isA<Err>());
      expect(vm.favorite, isFalse);
      expect(seen, [true, false]);
    });
  });

  group('external favorite listener', () {
    test('updates favorite when repository notifies a change', () {
      final vm = buildViewModel();
      final listener =
          verify(() => favorites.addListener(captureAny())).captured.single
              as void Function();
      expect(vm.favorite, isFalse);

      when(() => favorites.isFavorite(FavoriteType.artist, 'art'))
          .thenReturn(true);
      listener();

      expect(vm.favorite, isTrue);
    });

    test('does not notify when value is unchanged', () {
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

  group('onAddToQueue', () {
    test('callback always calls queue.addAll with the given priority',
        () async {
      final songs = [makeSong('s1'), makeSong('s2')];
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, false);
        return const Result.ok(null);
      });
      final vm = buildViewModel();

      final result = await vm.onAddToQueue(true);

      expect(result, isA<Ok>());
      verify(() => queue.addAll(songs, true)).called(1);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });

    test('callback uses priority=false when passed false', () async {
      final songs = [makeSong('s1')];
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, false);
        return const Result.ok(null);
      });
      final vm = buildViewModel();

      await vm.onAddToQueue(false);

      verify(() => queue.addAll(songs, false)).called(1);
    });

    test('appends even on the first batch (never replaces)', () async {
      final songs = [makeSong('s1')];
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, true);
        return const Result.ok(null);
      });
      final vm = buildViewModel();

      await vm.onAddToQueue(true);

      verify(() => queue.addAll(songs, true)).called(1);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });
  });

  group('play', () {
    test('first batch replaces queue and sets play on next media change',
        () async {
      final songs = [makeSong('s1'), makeSong('s2')];
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, true);
        return const Result.ok(null);
      });
      final vm = buildViewModel();

      final result = await vm.play();

      expect(result, isA<Ok>());
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 0)).called(1);
      verifyNever(() => queue.addAll(any(), any()));
    });

    test('later batches call queue.addAll with false', () async {
      final songs = [makeSong('s1')];
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((invocation) async {
        final cb = invocation.positionalArguments[1]
            as Future<void> Function(List<Song>, bool);
        await cb(songs, false);
        return const Result.ok(null);
      });
      final vm = buildViewModel();

      await vm.play();

      verify(() => queue.addAll(songs, false)).called(1);
      verifyNever(() => queue.replace(any(), any()));
      verifyNever(() => player.playOnNextMediaChange());
    });

    test('forwards shuffle flags (shuffleAlbums -> shuffleReleases)', () async {
      when(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: any(named: 'shuffleReleases'),
          shuffleSongs: any(named: 'shuffleSongs'),
        ),
      ).thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();

      await vm.play(shuffleAlbums: true, shuffleSongs: false);

      verify(
        () => subsonic.incrementallyLoadArtistSongs(
          any(),
          any(),
          shuffleReleases: true,
          shuffleSongs: false,
        ),
      ).called(1);
    });
  });

  group('getSongs', () {
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

      final result = await vm.getSongs();

      expect(result, isA<Ok>());
      expect((result as Ok).value, [s1, s2, s3]);
    });

    test('propagates error', () async {
      when(() => subsonic.getArtistSongs(any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel();

      final result = await vm.getSongs();

      expect(result, isA<Err>());
    });
  });

  test('dispose removes the favorites listener', () {
    final vm = buildViewModel();

    vm.dispose();

    verify(() => favorites.removeListener(any())).called(1);
  });
}