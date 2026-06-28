import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/playlists/create/create_playlist_viewmodel.dart';
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

void main() {
  setUpAll(() {
    registerFallbackValue(const <Song>[]);
    registerFallbackValue(<String>{});
  });

  late MockPlaylistRepository repo;

  setUp(() {
    repo = MockPlaylistRepository();
  });

  CreatePlaylistViewModel buildViewModel() =>
      CreatePlaylistViewModel(playlistRepository: repo);

  test('happy path no desc/songs: returns Ok(id), loading true->false', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));

    final vm = buildViewModel();
    final seen = <bool>[];
    vm.addListener(() => seen.add(vm.loading));

    final result = await vm.create('New Playlist');

    expect(result, isA<Ok<String>>());
    expect((result as Ok<String>).value, 'pl-1');
    expect(seen, [true, false]);
    verifyNever(() => repo.updatePlaylistMetadata(any()));
    verifyNever(() => repo.addTracks(any(), any()));
  });

  test('create Err: returns error, no metadata/tracks, loading reset', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => Result.error(Exception('network fail')));

    final vm = buildViewModel();
    final seen = <bool>[];
    vm.addListener(() => seen.add(vm.loading));

    final result = await vm.create('Bad Playlist');

    expect(result, isA<Err>());
    expect(seen, [true, false]);
    verifyNever(() => repo.updatePlaylistMetadata(any()));
    verifyNever(() => repo.addTracks(any(), any()));
  });

  test('non-empty description: updatePlaylistMetadata called; empty: not called',
      () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));
    when(() => repo.updatePlaylistMetadata(any(), comment: any(named: 'comment')))
        .thenAnswer((_) async => const Result.ok(null));

    final vm = buildViewModel();

    await vm.create('Name', description: 'My description');
    verify(() => repo.updatePlaylistMetadata('pl-1', comment: 'My description'))
        .called(1);

    await vm.create('Name', description: '');
    verifyNever(
      () => repo.updatePlaylistMetadata(any(), comment: any(named: 'comment')),
    );
  });

  test('non-empty songs: addTracks called; empty: not called', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));
    when(() => repo.addTracks(any(), any()))
        .thenAnswer((_) async => const Result.ok(null));

    final songs = [makeSong('s1'), makeSong('s2')];
    final vm = buildViewModel();

    await vm.create('Name', songs: songs);
    verify(() => repo.addTracks('pl-1', any())).called(1);

    await vm.create('Name');
    verifyNever(() => repo.addTracks(any(), any()));
  });

  test('description Err swallowed: overall still Ok(id)', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));
    when(() => repo.updatePlaylistMetadata(any(), comment: any(named: 'comment')))
        .thenAnswer((_) async => Result.error(Exception('desc fail')));

    final vm = buildViewModel();

    final result = await vm.create('Name', description: 'desc');

    expect(result, isA<Ok<String>>());
  });

  test('tracks Err swallowed: overall still Ok(id)', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));
    when(() => repo.addTracks(any(), any()))
        .thenAnswer((_) async => Result.error(Exception('add fail')));

    final vm = buildViewModel();

    final result = await vm.create('Name', songs: [makeSong('s1')]);

    expect(result, isA<Ok<String>>());
  });

  test('both desc + songs: both called, returns Ok(id)', () async {
    when(() => repo.create(any()))
        .thenAnswer((_) async => const Result.ok('pl-1'));
    when(() => repo.updatePlaylistMetadata(any(), comment: any(named: 'comment')))
        .thenAnswer((_) async => const Result.ok(null));
    when(() => repo.addTracks(any(), any()))
        .thenAnswer((_) async => const Result.ok(null));

    final vm = buildViewModel();

    final result = await vm.create(
      'Name',
      description: 'desc',
      songs: [makeSong('s1')],
    );

    expect(result, isA<Ok<String>>());
    verify(() => repo.updatePlaylistMetadata('pl-1', comment: 'desc')).called(1);
    verify(() => repo.addTracks('pl-1', any())).called(1);
  });

  test('create throws: finally resets loading and notifies', () async {
    when(() => repo.create(any())).thenThrow(Exception('unexpected'));

    final vm = buildViewModel();
    final seen = <bool>[];
    vm.addListener(() => seen.add(vm.loading));

    expect(() => vm.create('Name'), throwsException);
    await Future.delayed(Duration.zero);

    expect(seen, containsAll([true, false]));
    expect(vm.loading, isFalse);
  });
}