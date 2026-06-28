import 'package:crossonic/data/repositories/subsonic/server_support.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/settings/pages/scan_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSubsonicRepository extends Mock implements SubsonicRepository {}

class MockServerSupport extends Mock implements ServerSupport {}

ScanStatus notScanning({DateTime? lastScan}) => (
      scanning: false,
      isFullScan: null,
      lastScan: lastScan,
      scanStart: null,
      scanned: null,
    );

ScanStatus scanning({bool? isFullScan, int? scanned, DateTime? lastScan}) => (
      scanning: true,
      isFullScan: isFullScan,
      lastScan: lastScan,
      scanStart: DateTime.now(),
      scanned: scanned ?? 0,
    );

void main() {
  late MockSubsonicRepository subsonic;
  late MockServerSupport supports;

  setUp(() {
    subsonic = MockSubsonicRepository();
    supports = MockServerSupport();
    when(() => subsonic.supports).thenReturn(supports);
    when(() => supports.scanType).thenReturn(true);
  });

  ScanViewModel buildViewModel() => ScanViewModel(subsonic: subsonic);

  group('constructor', () {
    test('sets status to loading immediately', () {
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(notScanning()));

      final vm = buildViewModel();
      expect(vm.status, FetchStatus.loading);
      vm.dispose();
    });

    test('after flushMicrotasks status changed from loading', () async {
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(notScanning()));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, isNot(FetchStatus.loading));
      vm.dispose();
    });
  });

  group('_loadStatus', () {
    test('error → failure', () async {
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.error(Exception('network')));

      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      expect(vm.status, FetchStatus.failure);
      vm.dispose();
    });

    test('success while scanning → starts 250ms periodic poll', () {
      fakeAsync((async) {
        when(() => subsonic.getScanStatus())
            .thenAnswer((_) async => Result.ok(scanning()));

        final vm = buildViewModel();
        async.flushMicrotasks();

        expect(vm.status, FetchStatus.success);
        expect(vm.scanStatus.scanning, isTrue);

        // Advance 500ms — timer should have fired twice
        async.elapse(const Duration(milliseconds: 500));

        // Initial call + 2 timer-driven calls = at least 3
        verify(() => subsonic.getScanStatus()).called(greaterThanOrEqualTo(3));
        vm.dispose();
      });
    });

    test('not scanning -> no timer started', () {
      fakeAsync((async) {
        when(() => subsonic.getScanStatus())
            .thenAnswer((_) async => Result.ok(notScanning()));

        final vm = buildViewModel();
        async.flushMicrotasks();

        expect(vm.scanStatus.scanning, isFalse);
        verify(() => subsonic.getScanStatus()).called(1);

        async.elapse(const Duration(milliseconds: 500));
        verifyNever(() => subsonic.getScanStatus());
        vm.dispose();
      });
    });

    test('scanning→not-scanning transition cancels the timer', () {
      fakeAsync((async) {
        var callCount = 0;
        when(() => subsonic.getScanStatus()).thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            return Result.ok(scanning());
          }
          return Result.ok(notScanning());
        });

        final vm = buildViewModel();
        async.flushMicrotasks(); // call 1: scanning → starts timer

        async.elapse(const Duration(milliseconds: 250)); // call 2: scanning
        async.elapse(const Duration(milliseconds: 250)); // call 3: not scanning → cancels

        final callsAfterCancel = callCount;
        async.elapse(const Duration(milliseconds: 500));

        expect(callCount, equals(callsAfterCancel),
            reason: 'no further calls after timer cancelled');
        vm.dispose();
      });
    });

    test('??= guard: two scanning statuses do not spawn second timer', () {
      fakeAsync((async) {
        when(() => subsonic.getScanStatus())
            .thenAnswer((_) async => Result.ok(scanning()));
        when(() => subsonic.startScan(fullScan: any(named: 'fullScan')))
            .thenAnswer((_) async => Result.ok(scanning()));

        final vm = buildViewModel();
        async.flushMicrotasks(); // first _loadStatus → creates timer

        // Manually call again (simulating a second path that would try to create timer)
        vm.scan(false);
        async.flushMicrotasks(); // scan calls startScan + another _loadStatus inside timer

        // Only one timer should exist, so exactly 250ms spacing
        final callsBefore = verify(() => subsonic.getScanStatus()).callCount;
        async.elapse(const Duration(milliseconds: 250));
        // One timer tick = one additional call
        verify(() => subsonic.getScanStatus()).called(1);
        vm.dispose();
      });
    });
  });

  group('scan', () {
    test('scan(true): optimistic status + notify; Ok adopts result + starts timer; returns Ok', () async {
      final lastScan = DateTime(2024, 1, 1);
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(notScanning(lastScan: lastScan)));
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      when(() => subsonic.startScan(fullScan: any(named: 'fullScan')))
          .thenAnswer((_) async => Result.ok(scanning(isFullScan: true, lastScan: lastScan)));
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(scanning()));

      var notifications = 0;
      vm.addListener(() => notifications++);

      final resultFuture = vm.scan(true);
      // Optimistic update visible before await
      expect(vm.scanStatus.scanning, isTrue);
      expect(vm.scanStatus.isFullScan, isTrue);
      expect(vm.scanStatus.lastScan, lastScan);
      expect(vm.scanStatus.scanStart, isNotNull);
      expect(notifications, greaterThanOrEqualTo(1));

      final result = await resultFuture;
      expect(result, isA<Ok>());
      vm.dispose();
    });

    test('scan Err returns error', () async {
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(notScanning()));
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      when(() => subsonic.startScan(fullScan: any(named: 'fullScan')))
          .thenAnswer((_) async => Result.error(Exception('scan failed')));

      final result = await vm.scan(false);
      expect(result, isA<Err>());
      vm.dispose();
    });
  });

  group('dispose', () {
    test('cancels timer on dispose', () {
      fakeAsync((async) {
        when(() => subsonic.getScanStatus())
            .thenAnswer((_) async => Result.ok(scanning()));

        final vm = buildViewModel();
        async.flushMicrotasks();
        verify(() => subsonic.getScanStatus()).called(1);

        vm.dispose();

        async.elapse(const Duration(milliseconds: 500));
        verifyNever(() => subsonic.getScanStatus());
      });
    });
  });

  group('supportsScanType', () {
    test('returns pass-through from server supports', () {
      when(() => subsonic.getScanStatus())
          .thenAnswer((_) async => Result.ok(notScanning()));
      when(() => supports.scanType).thenReturn(false);

      final vm = buildViewModel();
      expect(vm.supportsScanType, isFalse);
      vm.dispose();
    });
  });
}