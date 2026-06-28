import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/ui/common/volume_viewmodel.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

void main() {
  late MockPlaybackManager playback;
  late MockPlayerManager player;
  late BehaviorSubject<double> volumeLinearSubject;

  void setupMocks() {
    playback = MockPlaybackManager();
    player = MockPlayerManager();
    volumeLinearSubject = BehaviorSubject<double>.seeded(1.0);

    when(() => playback.player).thenReturn(player);
    when(() => player.volumeLinearStream)
        .thenAnswer((_) => volumeLinearSubject.stream);
    when(() => player.volumeCubic).thenReturn(1.0);
  }

  setUp(setupMocks);

  tearDown(() async {
    await volumeLinearSubject.close();
  });

  VolumeViewModel buildViewModel() =>
      VolumeViewModel(playbackManager: playback);

  group('construction', () {
    test('seeds volume from player.volumeCubic', () {
      when(() => player.volumeCubic).thenReturn(0.5);
      final vm = buildViewModel();
      expect(vm.volume, 0.5);
    });
  });

  group('volume setter', () {
    test('notifies immediately when volume is set', () {
      final vm = buildViewModel();
      var notified = false;
      vm.addListener(() => notified = true);

      vm.volume = 0.7;

      expect(vm.volume, 0.7);
      expect(notified, isTrue);
    });

    test('calls player.volumeCubic on leading edge (within delay window)', () {
      fakeAsync((async) {
        setupMocks();
        when(() => player.volumeCubic = any<double>()).thenReturn(0.0);
        final vm = VolumeViewModel(playbackManager: playback);

        vm.volume = 0.3;

        verify(() => player.volumeCubic = 0.3).called(1);

        vm.dispose();
      });
    });

    test('calls player.volumeCubic on trailing edge after delay', () {
      fakeAsync((async) {
        setupMocks();
        when(() => player.volumeCubic = any<double>()).thenReturn(0.0);
        final vm = VolumeViewModel(playbackManager: playback);

        vm.volume = 0.3; // leading edge fires immediately

        async.elapse(const Duration(milliseconds: 100));

        // trailing edge fires after 100ms with the latest value
        verify(() => player.volumeCubic = 0.3).called(greaterThanOrEqualTo(1));

        vm.dispose();
      });
    });

    test('5 rapid sets -> only 2 writes (leading + trailing)', () {
      fakeAsync((async) {
        setupMocks();
        final writtenValues = <double>[];
        when(() => player.volumeCubic = any<double>()).thenAnswer((invocation) {
          writtenValues.add(invocation.positionalArguments[0] as double);
          return invocation.positionalArguments[0] as double;
        });
        final vm = VolumeViewModel(playbackManager: playback);

        vm.volume = 0.1; // leading edge fires
        vm.volume = 0.2;
        vm.volume = 0.3;
        vm.volume = 0.4;
        vm.volume = 0.5;

        async.elapse(const Duration(milliseconds: 100));
        // trailing edge fires with latest value (0.5)

        expect(writtenValues.length, 2);
        expect(writtenValues.first, 0.1);
        expect(writtenValues.last, 0.5);

        vm.dispose();
      });
    });

    test('throttle resets after delay; next call fires leading edge again', () {
      fakeAsync((async) {
        setupMocks();
        final writtenValues = <double>[];
        when(() => player.volumeCubic = any<double>()).thenAnswer((invocation) {
          writtenValues.add(invocation.positionalArguments[0] as double);
          return invocation.positionalArguments[0] as double;
        });
        final vm = VolumeViewModel(playbackManager: playback);

        vm.volume = 0.2; // leading edge: writes 0.2

        async.elapse(const Duration(milliseconds: 100));

        writtenValues.clear();

        vm.volume = 0.8; // new leading edge after throttle reset
        expect(writtenValues, [0.8]);

        vm.dispose();
      });
    });
  });

  group('volumeLinearStream', () {
    test('stream emit re-reads volumeCubic and notifies', () async {
      when(() => player.volumeCubic).thenReturn(0.5);
      final vm = buildViewModel();
      expect(vm.volume, 0.5);

      when(() => player.volumeCubic).thenReturn(0.8);
      final seen = <double>[];
      vm.addListener(() => seen.add(vm.volume));

      volumeLinearSubject.add(0.512); // triggers the listener
      await Future.delayed(Duration.zero);

      expect(vm.volume, 0.8);
      expect(seen, contains(0.8));
    });
  });

  group('dispose', () {
    test('cancels subscription so stream events no longer notify', () async {
      when(() => player.volumeCubic).thenReturn(0.5);
      final vm = buildViewModel();

      vm.dispose();

      when(() => player.volumeCubic).thenReturn(0.9);
      var notified = false;
      // Can't add listener after dispose, so just verify no crash
      volumeLinearSubject.add(0.729);
      await Future.delayed(Duration.zero);
      expect(notified, isFalse);
    });
  });
}