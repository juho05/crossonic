import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/album.dart';
import 'package:crossonic/data/repositories/subsonic/models/artist.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/data/repositories/subsonic/music_folders_repository.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/browse/browse_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockMusicFoldersRepository extends Mock
    implements MusicFoldersRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

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

Album makeAlbum(String id) => Album(
      id: id,
      name: 'Album $id',
      coverId: 'cover-$id',
      songs: null,
      songCount: 0,
      displayArtist: 'Artist',
      artists: const [],
      discTitles: const {},
      releaseType: ReleaseType.album,
      releaseDate: null,
      originalDate: null,
      version: null,
      musicBrainzId: null,
    );

Artist makeArtist(String id) => Artist(
      id: id,
      name: 'Artist $id',
      coverId: 'cover-$id',
      albums: null,
      albumCount: null,
      genres: const [],
    );

SearchResult makeSearchResult({
  List<Song>? songs,
  List<Album>? albums,
  List<Artist>? artists,
}) => (
      songs: songs ?? [],
      albums: albums ?? [],
      artists: artists ?? [],
    );

void main() {
  late MockSubsonicRepository subsonic;
  late MockMusicFoldersRepository musicFolders;
  late MockServerSupport supports;
  late StreamController<void> debounced;

  setUp(() {
    subsonic = MockSubsonicRepository();
    musicFolders = MockMusicFoldersRepository();
    supports = MockServerSupport();
    debounced = StreamController<void>.broadcast();

    when(() => musicFolders.debounced).thenAnswer((_) => debounced.stream);
    when(() => subsonic.supports).thenReturn(supports);
  });

  tearDown(() async {
    await debounced.close();
  });

  BrowseViewModel buildViewModel() => BrowseViewModel(
        subsonicRepository: subsonic,
        musicFolders: musicFolders,
      );

  group('updateSearchText', () {
    test('empty string clears results, sets searchMode=false, status initial',
        () async {
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.updateSearchText('');

      expect(vm.searchMode, isFalse);
      expect(vm.searchStatus, FetchStatus.initial);
      expect(vm.songs, isEmpty);
      expect(vm.albums, isEmpty);
      expect(vm.artists, isEmpty);
      expect(notified, isTrue);
    });

    test('non-empty search notifies loading then success with results',
        () async {
      final songs = List.generate(15, (i) => makeSong('s$i'));
      final albums = List.generate(5, (i) => makeAlbum('a$i'));
      final artists = List.generate(3, (i) => makeArtist('ar$i'));

      when(() => subsonic.search(
            any(),
            artistCount: any(named: 'artistCount'),
            albumCount: any(named: 'albumCount'),
            songCount: any(named: 'songCount'),
          )).thenAnswer((_) async => Result.ok(makeSearchResult(
            songs: songs,
            albums: albums,
            artists: artists,
          )));

      final vm = buildViewModel();
      final statuses = <FetchStatus>[];
      vm.addListener(() => statuses.add(vm.searchStatus));

      await vm.updateSearchText('hello');

      expect(statuses, contains(FetchStatus.loading));
      expect(statuses.last, FetchStatus.success);
      expect(vm.searchMode, isTrue);
      expect(vm.songs, hasLength(15));
      expect(vm.albums, hasLength(5));
      expect(vm.artists, hasLength(3));
    });

    test('failure -> status failure, notified', () async {
      when(() => subsonic.search(
            any(),
            artistCount: any(named: 'artistCount'),
            albumCount: any(named: 'albumCount'),
            songCount: any(named: 'songCount'),
          )).thenAnswer((_) async => Result.error(Exception('search failed')));

      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      await vm.updateSearchText('broken');

      expect(vm.searchStatus, FetchStatus.failure);
      expect(notified, isTrue);
    });

    test('calls search with songCount:15, albumCount:5, artistCount:3',
        () async {
      when(() => subsonic.search(
            any(),
            artistCount: any(named: 'artistCount'),
            albumCount: any(named: 'albumCount'),
            songCount: any(named: 'songCount'),
          )).thenAnswer((_) async => Result.ok(makeSearchResult()));

      final vm = buildViewModel();
      await vm.updateSearchText('query');

      verify(() => subsonic.search(
            'query',
            artistCount: 3,
            albumCount: 5,
            songCount: 15,
          )).called(1);
    });
  });

  test('music folder debounced event re-runs last search text', () async {
    when(() => subsonic.search(
          any(),
          artistCount: any(named: 'artistCount'),
          albumCount: any(named: 'albumCount'),
          songCount: any(named: 'songCount'),
        )).thenAnswer((_) async => Result.ok(makeSearchResult()));

    final vm = buildViewModel();
    await vm.updateSearchText('foo');

    debounced.add(null);
    await Future.delayed(Duration.zero);

    verify(() => subsonic.search(
          'foo',
          artistCount: any(named: 'artistCount'),
          albumCount: any(named: 'albumCount'),
          songCount: any(named: 'songCount'),
        )).called(2);
  });

  test('supportBPM returns supports.getSongs', () {
    when(() => supports.getSongs).thenReturn(true);
    final vm = buildViewModel();
    expect(vm.supportBPM, isTrue);

    when(() => supports.getSongs).thenReturn(false);
    expect(vm.supportBPM, isFalse);
  });
}