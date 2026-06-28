import 'dart:async';

import 'package:crossonic/data/repositories/subsonic/models/listenbrainz_config.dart';
import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/settings/pages/listenbrainz_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

ListenBrainzConfig makeConfig({
  String? username = 'user',
  bool scrobble = true,
  bool syncFeedback = false,
}) => ListenBrainzConfig(
      username: username,
      scrobble: scrobble,
      syncFeedback: syncFeedback,
    );

void main() {
  late MockSubsonicRepository subsonic;
  late MockServerSupport supports;

  setUp(() {
    subsonic = MockSubsonicRepository();
    supports = MockServerSupport();
    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.listenBrainzSettings).thenReturn(true);
  });

  ListenBrainzViewModel buildViewModel() =>
      ListenBrainzViewModel(subsonicRepository: subsonic);

  group('load', () {
    test('initial->loading->success, fields populated, ≥2 notifications', () async {
      when(() => subsonic.getListenBrainzConfig())
          .thenAnswer((_) async => Result.ok(makeConfig()));

      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.load();

      expect(vm.status, FetchStatus.success);
      expect(vm.username, 'user');
      expect(vm.scrobbleEnabled, isTrue);
      expect(vm.syncFavorites, isFalse);
      expect(notifications, greaterThanOrEqualTo(2));
    });

    test('failure -> status failure + notify, username stays null', () async {
      when(() => subsonic.getListenBrainzConfig())
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      await vm.load();

      expect(vm.status, FetchStatus.failure);
      expect(vm.username, isNull);
      expect(notifications, greaterThanOrEqualTo(2));
    });
  });

  group('connect', () {
    test('submitting true mid-call, then false; fields from result; returns Ok', () async {
      final completer = Completer<Result<ListenBrainzConfig>>();
      when(() => subsonic.connectListenBrainz(any()))
          .thenAnswer((_) => completer.future);

      final vm = buildViewModel();
      final submittingStates = <bool>[];
      vm.addListener(() => submittingStates.add(vm.submitting));

      final future = vm.connect('token123');
      expect(vm.submitting, isTrue);

      completer.complete(Result.ok(makeConfig(username: 'newuser', scrobble: true)));
      final result = await future;

      expect(result, isA<Ok>());
      expect(vm.submitting, isFalse);
      expect(vm.username, 'newuser');
      expect(vm.scrobbleEnabled, isTrue);
      expect(submittingStates, contains(true));
      expect(submittingStates.last, isFalse);
    });

    test('connect failure: submitting reset; returns error; fields unchanged', () async {
      when(() => subsonic.connectListenBrainz(any()))
          .thenAnswer((_) async => Result.error(Exception('auth failed')));

      final vm = buildViewModel();
      final result = await vm.connect('bad-token');

      expect(result, isA<Err>());
      expect(vm.submitting, isFalse);
      expect(vm.username, isNull);
    });
  });

  group('updateSettings', () {
    test('optimistic value visible before await; final from server', () async {
      when(() => subsonic.getListenBrainzConfig())
          .thenAnswer((_) async => Result.ok(makeConfig(scrobble: false)));
      final vm = buildViewModel();
      await vm.load();
      expect(vm.scrobbleEnabled, isFalse);

      final completer = Completer<Result<ListenBrainzConfig>>();
      when(() => subsonic.updateListenBrainzConfig(
            scrobble: any(named: 'scrobble'),
            syncFeedback: any(named: 'syncFeedback'),
          )).thenAnswer((_) => completer.future);

      final notifications = <bool>[];
      vm.addListener(() => notifications.add(vm.scrobbleEnabled));

      final future = vm.updateSettings(scrobbleEnabled: true);
      // Optimistic update
      expect(vm.scrobbleEnabled, isTrue);
      expect(notifications, contains(true));

      completer.complete(Result.ok(makeConfig(scrobble: true)));
      final result = await future;

      expect(result, isA<Ok>());
      expect(vm.scrobbleEnabled, isTrue);
    });

    test('failure: rolled back; error returned', () async {
      when(() => subsonic.getListenBrainzConfig())
          .thenAnswer((_) async => Result.ok(makeConfig(scrobble: false)));
      final vm = buildViewModel();
      await vm.load();
      expect(vm.scrobbleEnabled, isFalse);

      when(() => subsonic.updateListenBrainzConfig(
            scrobble: any(named: 'scrobble'),
            syncFeedback: any(named: 'syncFeedback'),
          )).thenAnswer((_) async => Result.error(Exception('server error')));

      final result = await vm.updateSettings(scrobbleEnabled: true);

      expect(result, isA<Err>());
      expect(vm.scrobbleEnabled, isFalse, reason: 'rolled back to original');
    });

    test('null scrobbleEnabled keeps current scrobble value', () async {
      when(() => subsonic.getListenBrainzConfig())
          .thenAnswer((_) async => Result.ok(makeConfig(scrobble: true)));
      final vm = buildViewModel();
      await vm.load();
      expect(vm.scrobbleEnabled, isTrue);

      when(() => subsonic.updateListenBrainzConfig(
            scrobble: any(named: 'scrobble'),
            syncFeedback: any(named: 'syncFeedback'),
          )).thenAnswer((_) async => Result.ok(makeConfig(scrobble: true, syncFeedback: true)));

      await vm.updateSettings(syncFavorites: true);

      expect(vm.scrobbleEnabled, isTrue);
    });
  });

  group('settingsSupported', () {
    test('returns the flag from server supports', () {
      when(() => supports.listenBrainzSettings).thenReturn(false);
      final vm = buildViewModel();
      expect(vm.settingsSupported, isFalse);
      vm.dispose();
    });

    test('returns true when supported', () {
      when(() => supports.listenBrainzSettings).thenReturn(true);
      final vm = buildViewModel();
      expect(vm.settingsSupported, isTrue);
      vm.dispose();
    });
  });
}