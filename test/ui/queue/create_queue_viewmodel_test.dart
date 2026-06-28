import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/ui/queue/create_queue_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

void main() {
  late MockPlaybackManager playback;
  late MockQueueManager queue;

  setUp(() {
    playback = MockPlaybackManager();
    queue = MockQueueManager();

    when(() => playback.queue).thenReturn(queue);
    when(() => queue.createNewQueue(any())).thenAnswer(
      (_) async => Queue(
        id: 'new-id',
        name: 'New Queue',
        songCount: 0,
        currentIndex: -1,
        isDefault: false,
      ),
    );
  });

  CreateQueueViewModel buildViewModel() =>
      CreateQueueViewModel(playbackManager: playback);

  test('isValid is false initially', () {
    final vm = buildViewModel();
    expect(vm.isValid, isFalse);
  });

  group('name setter', () {
    test('non-empty name makes isValid true and notifies', () {
      final vm = buildViewModel();
      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.isValid));

      vm.name = 'My Queue';

      expect(vm.isValid, isTrue);
      expect(seen, [true]);
    });

    test('empty name makes isValid false and notifies', () {
      final vm = buildViewModel();
      vm.name = 'My Queue';

      final seen = <bool>[];
      vm.addListener(() => seen.add(vm.isValid));

      vm.name = '';

      expect(vm.isValid, isFalse);
      expect(seen, [false]);
    });

    test('setting same value still notifies', () {
      final vm = buildViewModel();
      vm.name = 'Queue';

      var notifyCount = 0;
      vm.addListener(() => notifyCount++);

      vm.name = 'Queue';

      expect(notifyCount, 1);
    });
  });

  group('create', () {
    test('calls createNewQueue with current name', () async {
      final vm = buildViewModel();
      vm.name = 'Roadtrip';

      await vm.create();

      verify(() => queue.createNewQueue('Roadtrip')).called(1);
    });

    test('rethrows when createNewQueue throws', () async {
      when(() => queue.createNewQueue(any())).thenThrow(Exception('fail'));
      final vm = buildViewModel();
      vm.name = 'Bad Queue';

      expect(() => vm.create(), throwsException);
    });
  });
}