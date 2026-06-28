import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/data/repositories/auth/models/server_features.dart';
import 'package:crossonic/data/services/opensubsonic/auth.dart';
import 'package:crossonic/data/services/opensubsonic/models/albumid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/artistid3_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/child_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/item_date_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/playlist_model.dart';
import 'package:crossonic/data/services/opensubsonic/models/replay_gain_model.dart';
import 'package:crossonic/data/services/opensubsonic/subsonic_service.dart';
import 'package:crossonic/ui/common/dialogs/media_info_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicService extends Mock implements SubsonicService {}

class MockAuthRepository extends Mock implements AuthRepository {}

final _connection = Connection(
  baseUri: Uri.parse('https://music.example.com'),
  auth: EmptyAuth(),
  supportsPost: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(_connection);
  });

  late MockSubsonicService service;
  late MockAuthRepository auth;

  setUp(() {
    service = MockSubsonicService();
    auth = MockAuthRepository();
    when(() => auth.con).thenReturn(_connection);
    when(() => auth.serverFeatures).thenReturn(ValueNotifier(ServerFeatures()));
  });

  // ----------------------------- song -----------------------------

  group('song', () {
    test('Err -> status failure', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      vm.dispose();
    });

    test('minimal song: only ID field present', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(id: 's42')));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's42');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.fields.length, 1);
      expect(vm.fields.first.$1, 'ID');
      expect(vm.fields.first.$2, 's42');
      vm.dispose();
    });

    test('rating == 0 and bpm == 0 omitted; non-zero included', () async {
      when(() => service.getSong(any(), 'zero'))
          .thenAnswer((_) async =>
              Result.ok(_makeSong(id: 'zero', userRating: 0, avgRating: 0, bpm: 0)));
      when(() => service.getSong(any(), 'nonzero'))
          .thenAnswer((_) async =>
              Result.ok(_makeSong(id: 'nonzero', userRating: 3, avgRating: 3.5, bpm: 120)));

      final vmZero = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 'zero');
      await Future.delayed(Duration.zero);
      final labelsZero = vmZero.fields.map((f) => f.$1).toSet();
      expect(labelsZero, isNot(contains('User rating')));
      expect(labelsZero, isNot(contains('Average rating')));
      expect(labelsZero, isNot(contains('BPM')));
      vmZero.dispose();

      final vmNonzero = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 'nonzero');
      await Future.delayed(Duration.zero);
      final labelsNonzero = vmNonzero.fields.map((f) => f.$1).toSet();
      expect(labelsNonzero, contains('User rating'));
      expect(labelsNonzero, contains('Average rating'));
      expect(labelsNonzero, contains('BPM'));
      vmNonzero.dispose();
    });

    test('single genre list -> "Genre" label', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(genres: [(name: 'Rock')])));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      expect(vm.fields.any((f) => f.$1 == 'Genre'), isTrue);
      expect(vm.fields.any((f) => f.$1 == 'Genres'), isFalse);
      vm.dispose();
    });

    test('multiple genres -> "Genres" label, joined values', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async =>
              Result.ok(_makeSong(genres: [(name: 'Rock'), (name: 'Pop')])));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      final field = vm.fields.firstWhere((f) => f.$1 == 'Genres');
      expect(field.$2, 'Rock, Pop');
      vm.dispose();
    });

    test('year shown when both release dates absent', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(year: 2020)));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      expect(vm.fields.any((f) => f.$1 == 'Year'), isTrue);
      vm.dispose();
    });

    test('year hidden when both releaseDate and originalReleaseDate present', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(
                year: 2020,
                releaseDate: ItemDateModel(year: 2020, month: null, day: null),
                originalReleaseDate: ItemDateModel(year: 2019, month: null, day: null),
              )));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      expect(vm.fields.any((f) => f.$1 == 'Year'), isFalse);
      vm.dispose();
    });

    test('MBID URL present on crossonic server', () async {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(ServerFeatures(isCrossonic: true)));
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(mbid: 'some-mbid')));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      final field = vm.fields.firstWhere((f) => f.$1 == 'MBID');
      expect(field.$3, isNotNull);
      expect(field.$3!.host, 'musicbrainz.org');
      vm.dispose();
    });

    test('MBID URL null on non-crossonic server', () async {
      when(() => auth.serverFeatures).thenReturn(ValueNotifier(ServerFeatures(isCrossonic: false)));
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(mbid: 'some-mbid')));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      final field = vm.fields.firstWhere((f) => f.$1 == 'MBID');
      expect(field.$3, isNull);
      vm.dispose();
    });

    test('replay gains included when set', () async {
      when(() => service.getSong(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeSong(
                replayGain: ReplayGainModel(
                  trackGain: -2.5,
                  albumGain: -3.0,
                  trackPeak: null,
                  albumPeak: null,
                  baseGain: null,
                  fallbackGain: -1.0,
                ),
              )));

      final vm = MediaInfoDialogViewModel.song(
          subsonicService: service, authRepository: auth, id: 's1');
      await Future.delayed(Duration.zero);

      final labels = vm.fields.map((f) => f.$1).toSet();
      expect(labels, contains('Track gain'));
      expect(labels, contains('Album gain'));
      expect(labels, contains('Fallback gain'));
      vm.dispose();
    });
  });

  // ----------------------------- album ----------------------------

  group('album', () {
    test('Err -> status failure', () async {
      when(() => service.getAlbum(any(), any()))
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'a1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      vm.dispose();
    });

    test('success: name and required fields present', () async {
      when(() => service.getAlbum(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeAlbum(id: 'a1', name: 'My Album')));

      final vm = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'a1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.name, 'My Album');
      final labels = vm.fields.map((f) => f.$1).toSet();
      expect(labels, containsAll(['ID', 'Duration', 'Song count']));
      vm.dispose();
    });

    test('no releaseMbid -> MBID label; releaseMbid present -> Release group MBID', () async {
      when(() => service.getAlbum(any(), 'no-rel'))
          .thenAnswer((_) async => Result.ok(_makeAlbum(id: 'no-rel', mbid: 'x')));
      when(() => service.getAlbum(any(), 'with-rel'))
          .thenAnswer((_) async => Result.ok(_makeAlbum(id: 'with-rel', mbid: 'x', releaseMbid: 'y')));

      final vmNo = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'no-rel');
      await Future.delayed(Duration.zero);
      expect(vmNo.fields.any((f) => f.$1 == 'MBID'), isTrue);
      expect(vmNo.fields.any((f) => f.$1 == 'Release group MBID'), isFalse);
      vmNo.dispose();

      final vmWith = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'with-rel');
      await Future.delayed(Duration.zero);
      expect(vmWith.fields.any((f) => f.$1 == 'Release group MBID'), isTrue);
      vmWith.dispose();
    });

    test('single releaseType -> "Release type"; multiple -> "Release types"', () async {
      when(() => service.getAlbum(any(), 'one'))
          .thenAnswer((_) async => Result.ok(_makeAlbum(id: 'one', releaseTypes: ['Album'])));
      when(() => service.getAlbum(any(), 'many'))
          .thenAnswer((_) async =>
              Result.ok(_makeAlbum(id: 'many', releaseTypes: ['Album', 'Compilation'])));

      final vmOne = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'one');
      await Future.delayed(Duration.zero);
      expect(vmOne.fields.any((f) => f.$1 == 'Release type'), isTrue);
      vmOne.dispose();

      final vmMany = MediaInfoDialogViewModel.album(
          subsonicService: service, authRepository: auth, id: 'many');
      await Future.delayed(Duration.zero);
      expect(vmMany.fields.any((f) => f.$1 == 'Release types'), isTrue);
      vmMany.dispose();
    });
  });

  // ----------------------------- artist ---------------------------

  group('artist', () {
    test('Err -> status failure', () async {
      when(() => service.getArtist(any(), any()))
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = MediaInfoDialogViewModel.artist(
          subsonicService: service, authRepository: auth, id: 'ar1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      vm.dispose();
    });

    test('success: name and ID present', () async {
      when(() => service.getArtist(any(), any()))
          .thenAnswer((_) async => Result.ok(_makeArtist(id: 'ar1', name: 'My Artist')));

      final vm = MediaInfoDialogViewModel.artist(
          subsonicService: service, authRepository: auth, id: 'ar1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.name, 'My Artist');
      expect(vm.fields.any((f) => f.$1 == 'ID'), isTrue);
      vm.dispose();
    });

    test('single role -> "Role"; multiple -> "Roles"', () async {
      when(() => service.getArtist(any(), 'one'))
          .thenAnswer((_) async => Result.ok(_makeArtist(id: 'one', roles: ['Vocalist'])));
      when(() => service.getArtist(any(), 'two'))
          .thenAnswer((_) async =>
              Result.ok(_makeArtist(id: 'two', roles: ['Vocalist', 'Producer'])));

      final vmOne = MediaInfoDialogViewModel.artist(
          subsonicService: service, authRepository: auth, id: 'one');
      await Future.delayed(Duration.zero);
      expect(vmOne.fields.any((f) => f.$1 == 'Role'), isTrue);
      vmOne.dispose();

      final vmTwo = MediaInfoDialogViewModel.artist(
          subsonicService: service, authRepository: auth, id: 'two');
      await Future.delayed(Duration.zero);
      expect(vmTwo.fields.any((f) => f.$1 == 'Roles'), isTrue);
      vmTwo.dispose();
    });
  });

  // ----------------------------- playlist -------------------------

  group('playlist', () {
    test('Err -> status failure', () async {
      when(() => service.getPlaylist(any(), any()))
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = MediaInfoDialogViewModel.playlist(
          subsonicService: service, authRepository: auth, id: 'p1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      vm.dispose();
    });

    test('success: required fields present', () async {
      when(() => service.getPlaylist(any(), any()))
          .thenAnswer((_) async => Result.ok(_makePlaylist(id: 'p1', name: 'My Playlist')));

      final vm = MediaInfoDialogViewModel.playlist(
          subsonicService: service, authRepository: auth, id: 'p1');
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.success);
      expect(vm.name, 'My Playlist');
      final labels = vm.fields.map((f) => f.$1).toSet();
      expect(labels, containsAll(['ID', 'Created', 'Updated', 'Song count', 'Duration']));
      vm.dispose();
    });
  });
}

// ---- builders ----

ChildModel _makeSong({
  String id = 's1',
  int? year,
  String? mbid,
  int? userRating,
  double? avgRating,
  int? bpm,
  ItemDateModel? releaseDate,
  ItemDateModel? originalReleaseDate,
  ReplayGainModel? replayGain,
  List<({String name})>? genres,
}) =>
    ChildModel(
      id: id,
      parent: null,
      isDir: false,
      title: 'T',
      album: null,
      artist: null,
      track: null,
      year: year,
      genre: null,
      coverArt: null,
      size: null,
      contentType: null,
      suffix: null,
      transcodedContentType: null,
      transcodedSuffix: null,
      duration: null,
      bitRate: null,
      bitDepth: null,
      samplingRate: null,
      channelCount: null,
      path: null,
      isVideo: null,
      userRating: userRating,
      averageRating: avgRating,
      playCount: null,
      discNumber: null,
      created: null,
      starred: null,
      albumId: null,
      artistId: null,
      type: null,
      mediaType: null,
      bookmarkPosition: null,
      originalWidth: null,
      originalHeight: null,
      played: null,
      bpm: bpm,
      comment: null,
      sortName: null,
      musicBrainzId: mbid,
      genres: genres,
      artists: null,
      displayArtist: null,
      albumArtists: null,
      displayAlbumArtist: null,
      contributors: null,
      displayComposer: null,
      moods: null,
      replayGain: replayGain,
      explicitStatus: null,
      originalReleaseDate: originalReleaseDate,
      releaseDate: releaseDate,
    );

AlbumID3Model _makeAlbum({
  String id = 'a1',
  String name = 'Album',
  String? mbid,
  String? releaseMbid,
  List<String>? releaseTypes,
}) =>
    AlbumID3Model(
      id: id,
      name: name,
      version: null,
      artist: null,
      artistId: null,
      coverArt: null,
      songCount: 0,
      duration: 120,
      playCount: null,
      created: DateTime(2024),
      starred: null,
      year: null,
      genre: null,
      played: null,
      userRating: null,
      averageRating: null,
      recordLabels: null,
      musicBrainzId: mbid,
      releaseMbid: releaseMbid,
      genres: null,
      artists: null,
      displayArtist: null,
      releaseTypes: releaseTypes,
      moods: null,
      sortName: null,
      originalReleaseDate: null,
      releaseDate: null,
      isCompilation: null,
      explicitStatus: null,
      discTitles: null,
      song: null,
    );

ArtistID3Model _makeArtist({
  String id = 'ar1',
  String name = 'Artist',
  List<String>? roles,
}) =>
    ArtistID3Model(
      id: id,
      name: name,
      coverArt: null,
      artistImageUrl: null,
      albumCount: null,
      starred: null,
      musicBrainzId: null,
      sortName: null,
      roles: roles,
      userRating: null,
      averageRating: null,
      album: null,
    );

PlaylistModel _makePlaylist({String id = 'p1', String name = 'Playlist'}) =>
    PlaylistModel(
      id: id,
      name: name,
      comment: null,
      owner: null,
      public: null,
      songCount: 5,
      duration: 300,
      created: DateTime(2024),
      changed: DateTime(2024, 6),
      coverArt: null,
      allowedUser: null,
      entry: null,
    );