import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/data/repositories/subsonic/favorites_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/song_list_item_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

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

void main() {
  setUpAll(() {
    registerFallbackValue(FavoriteType.song);
    registerFallbackValue(makeSong('fallback'));
    registerFallbackValue(const <Song>[]);
  });

  late MockFavoritesRepository favorites;
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late MockQueueManager queue;
  late BehaviorSubject<Song?> current;
  late BehaviorSubject<PlaybackStatus> status;

  setUp(() {
    favorites = MockFavoritesRepository();
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    queue = MockQueueManager();
    current = BehaviorSubject<Song?>.seeded(null);
    status = BehaviorSubject<PlaybackStatus>.seeded(PlaybackStatus.stopped);

    when(() => playback.player).thenReturn(player);
    when(() => playback.queue).thenReturn(queue);
    when(() => queue.current).thenAnswer((_) => current.stream);
    when(() => player.playbackStatus).thenAnswer((_) => status.stream);
    when(() => player.playOnNextMediaChange()).thenReturn(null);
    when(() => player.play()).thenAnswer((_) async {});
    when(() => player.pause()).thenAnswer((_) async {});
    when(() => queue.replace(any(), any())).thenAnswer((_) async {});
    when(() => queue.add(any(), any())).thenAnswer((_) async {});
    when(() => favorites.isFavorite(any(), any())).thenReturn(false);
  });

  tearDown(() async {
    await current.close();
    await status.close();
  });

  SongListItemViewModel buildViewModel({
    Song? song,
    bool disablePlaybackStatus = false,
  }) =>
      SongListItemViewModel(
        favoritesRepository: favorites,
        playbackManager: playback,
        song: song ?? makeSong('a'),
        disablePlaybackStatus: disablePlaybackStatus,
      );

  Future<void> pump() => Future.delayed(Duration.zero);

  group('playbackStatus', () {
    test('is null while the song is not the current one', () {
      final vm = buildViewModel();
      expect(vm.playbackStatus, isNull);
    });

    test('reflects the player status once the song becomes current', () async {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      current.add(makeSong('a'));
      status.add(PlaybackStatus.playing);
      await pump();

      expect(vm.playbackStatus, PlaybackStatus.playing);
      expect(notifications, greaterThan(0),
          reason: 'listeners notified when the song became current');
    });

    test('returns to null when a different song becomes current', () async {
      final vm = buildViewModel();
      current.add(makeSong('a'));
      status.add(PlaybackStatus.playing);
      await pump();
      expect(vm.playbackStatus, PlaybackStatus.playing);

      current.add(makeSong('b'));
      await pump();

      expect(vm.playbackStatus, isNull);
    });

    test('reflects an already-current song at construction', () {
      current.add(makeSong('a'));
      status.add(PlaybackStatus.playing);

      final vm = buildViewModel();

      expect(vm.playbackStatus, PlaybackStatus.playing);
    });

    test('never tracks status when playback status is disabled', () async {
      final vm = buildViewModel(disablePlaybackStatus: true);

      current.add(makeSong('a'));
      status.add(PlaybackStatus.playing);
      await pump();

      expect(vm.playbackStatus, isNull);
      verifyNever(() => queue.current);
    });
  });

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
      verify(() => favorites.setFavorite(FavoriteType.song, 'a', true))
          .called(1);
    });

    test('unfavorites and persists false when already favorite', () async {
      when(() => favorites.isFavorite(FavoriteType.song, 'a')).thenReturn(true);
      when(() => favorites.setFavorite(any(), any(), any()))
          .thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      expect(vm.favorite, isTrue);

      final result = await vm.toggleFavorite();

      expect(result, isA<Ok>());
      expect(vm.favorite, isFalse);
      verify(() => favorites.setFavorite(FavoriteType.song, 'a', false))
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
        verify(() => favorites.addListener(captureAny())).captured.first
            as void Function();
    expect(vm.favorite, isFalse);
    var notified = false;
    vm.addListener(() => notified = true);

    when(() => favorites.isFavorite(FavoriteType.song, 'a')).thenReturn(true);
    listener();

    expect(vm.favorite, isTrue);
    expect(notified, isTrue);
  });

  test('dispose stops reacting to external favorite changes', () {
    final vm = buildViewModel();
    final listener =
        verify(() => favorites.addListener(captureAny())).captured.first
            as void Function();

    vm.dispose();
    verify(() => favorites.removeListener(listener)).called(1);
  });

  group('playback actions', () {
    test('playSong arms play-on-change and replaces the queue', () async {
      final song = makeSong('a');
      final vm = buildViewModel(song: song);

      await vm.playSong();

      verify(() => player.playOnNextMediaChange()).called(1);
      verify(() => queue.replace([song])).called(1);
    });

    test('play and pause delegate to the player', () async {
      final vm = buildViewModel();

      await vm.play();
      await vm.pause();

      verify(() => player.play()).called(1);
      verify(() => player.pause()).called(1);
    });

    test('addToQueue adds the song with the given priority', () {
      final song = makeSong('a');
      final vm = buildViewModel(song: song);

      vm.addToQueue(true);

      verify(() => queue.add(song, true)).called(1);
    });
  });
}
