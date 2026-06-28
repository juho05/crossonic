import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/common/album_list_item_viewmodel.dart';
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
      coverId: 'cover-$id',
      title: 'Song $id',
      displayArtist: 'Artist',
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

Album makeAlbum({String id = 'album-1'}) => Album(
      id: id,
      name: 'Album',
      coverId: 'cover',
      releaseDate: null,
      originalDate: null,
      songs: const [],
      songCount: 0,
      displayArtist: 'Artist',
      artists: const [],
      discTitles: const {},
      releaseType: ReleaseType.album,
      version: null,
      musicBrainzId: null,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(FavoriteType.album);
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(makeAlbum());
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

  AlbumListItemViewModel buildViewModel({Album? album}) =>
      AlbumListItemViewModel(
        favoritesRepository: favorites,
        playbackManager: playback,
        subsonicRepository: subsonic,
        album: album ?? makeAlbum(),
      );

  group('toggleFavorite', () {
    test('optimistically marks favorite and persists', () async {
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      expect(vm.favorite, isTrue);
      expect(notified, isTrue);
      verify(() => favorites.setFavorite(FavoriteType.album, 'album-1', true))
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
      expect(seen, [true, false],
          reason: 'listeners notified of the optimistic change then rollback');
    });
  });

  test('reflects external favorite changes from the repository', () {
    final vm = buildViewModel();
    final listener =
        verify(() => favorites.addListener(captureAny())).captured.single
            as void Function();
    expect(vm.favorite, isFalse);

    when(() => favorites.isFavorite(FavoriteType.album, 'album-1'))
        .thenReturn(true);
    listener();

    expect(vm.favorite, isTrue);
  });

  group('play', () {
    test('replaces the queue with the album songs', () async {
      final songs = [makeSong('a'), makeSong('b')];
      when(() => subsonic.getAlbumSongs(any()))
          .thenAnswer((_) async => Result.ok(songs));
      final vm = buildViewModel();

      final result = await vm.play();

      expect(result, isA<Ok>());
      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace(songs, 0)).called(1);
    });

    test('propagates the error and does not touch the queue', () async {
      final failure = Exception('nope');
      when(() => subsonic.getAlbumSongs(any()))
          .thenAnswer((_) async => Result.error(failure));
      final vm = buildViewModel();

      final result = await vm.play();

      expect((result as Err).error, same(failure));
      verifyNever(() => player.playOnNextMediaChange());
      verifyNever(() => queue.replace(any(), any()));
    });
  });

  group('addToQueue', () {
    test('appends the album songs to the queue', () async {
      final songs = [makeSong('a'), makeSong('b')];
      when(() => subsonic.getAlbumSongs(any()))
          .thenAnswer((_) async => Result.ok(songs));
      final vm = buildViewModel();

      final result = await vm.addToQueue(true);

      expect(result, isA<Ok>());
      verify(() => queue.addAll(songs, true)).called(1);
    });

    test('propagates the error and does not enqueue', () async {
      when(() => subsonic.getAlbumSongs(any()))
          .thenAnswer((_) async => Result.error(Exception('nope')));
      final vm = buildViewModel();

      final result = await vm.addToQueue(false);

      expect(result, isA<Err>());
      verifyNever(() => queue.addAll(any(), any()));
    });
  });
}