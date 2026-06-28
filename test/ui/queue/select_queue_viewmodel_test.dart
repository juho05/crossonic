import 'package:crossonic/data/repositories/audio/playback_manager.dart';
import 'package:crossonic/data/repositories/audio/player_manager.dart';
import 'package:crossonic/data/repositories/audio/queue/queue.dart';
import 'package:crossonic/data/repositories/audio/queue/queue_manager.dart';
import 'package:crossonic/ui/queue/select_queue_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPlaybackManager extends Mock implements PlaybackManager {}

class MockPlayerManager extends Mock implements PlayerManager {}

class MockQueueManager extends Mock implements QueueManager {}

Queue makeQueue({
  String id = 'default',
  String name = 'Default',
  bool isDefault = false,
}) =>
    Queue(id: id, name: name, songCount: 0, currentIndex: 0, isDefault: isDefault);

void main() {
  late MockPlaybackManager playback;
  late MockQueueManager queue;

  setUp(() {
    playback = MockPlaybackManager();
    queue = MockQueueManager();

    when(() => playback.queue).thenReturn(queue);
    when(() => queue.currentQueueId).thenReturn('current-id');
    when(() => queue.getQueues(filter: any(named: 'filter')))
        .thenAnswer((_) async => []);
    when(() => queue.switchQueue(any())).thenAnswer((_) async {});
    when(() => queue.deleteQueue(any())).thenAnswer((_) async {});
  });

  Future<SelectQueueViewModel> buildViewModel() async {
    final vm = SelectQueueViewModel(playbackManager: playback);
    await Future.delayed(Duration.zero);
    return vm;
  }

  test('initial load reflects getQueues result and notifies', () async {
    when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
      (_) async => [makeQueue(id: 'a', name: 'Alpha')],
    );

    final vm = SelectQueueViewModel(playbackManager: playback);
    var notified = false;
    vm.addListener(() => notified = true);
    await Future.delayed(Duration.zero);

    expect(vm.queues.length, 1);
    expect(vm.queues.first.id, 'a');
    expect(notified, isTrue);
  });

  group('reordering', () {
    test('both present and distinct: current at 0, default at 1', () async {
      when(() => queue.currentQueueId).thenReturn('current');
      when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
        (_) async => [
          makeQueue(id: 'other', name: 'Other'),
          makeQueue(id: 'default', name: 'Default', isDefault: true),
          makeQueue(id: 'current', name: 'Current'),
        ],
      );

      final vm = await buildViewModel();

      expect(vm.queues[0].id, 'current');
      expect(vm.queues[1].id, 'default');
      expect(vm.queues.length, 3);
    });

    test('current == default: single reorder, no duplication', () async {
      when(() => queue.currentQueueId).thenReturn('default');
      when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
        (_) async => [
          makeQueue(id: 'other', name: 'Other'),
          makeQueue(id: 'default', name: 'Default', isDefault: true),
        ],
      );

      final vm = await buildViewModel();

      expect(vm.queues[0].id, 'default');
      expect(vm.queues.length, 2);
    });

    test('no default in list: only current floated', () async {
      when(() => queue.currentQueueId).thenReturn('current');
      when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
        (_) async => [
          makeQueue(id: 'alpha'),
          makeQueue(id: 'current'),
        ],
      );

      final vm = await buildViewModel();

      expect(vm.queues[0].id, 'current');
      expect(vm.queues.length, 2);
    });

    test('current absent: no crash, default still floated', () async {
      when(() => queue.currentQueueId).thenReturn('missing');
      when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
        (_) async => [
          makeQueue(id: 'alpha'),
          makeQueue(id: 'default', isDefault: true),
        ],
      );

      final vm = await buildViewModel();

      expect(vm.queues[0].id, 'default');
      expect(vm.queues.length, 2);
    });

    test('empty result: empty list and notifies', () async {
      when(() => queue.getQueues(filter: any(named: 'filter')))
          .thenAnswer((_) async => []);

      final vm = SelectQueueViewModel(playbackManager: playback);
      var notified = false;
      vm.addListener(() => notified = true);
      await Future.delayed(Duration.zero);

      expect(vm.queues, isEmpty);
      expect(notified, isTrue);
    });
  });

  test('filter calls getQueues with given filter string', () async {
    final vm = await buildViewModel();

    vm.filter = 'abc';
    await Future.delayed(Duration.zero);

    verify(() => queue.getQueues(filter: 'abc')).called(1);
  });

  test('queue-manager notification triggers reload and notifies', () async {
    when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
      (_) async => [makeQueue(id: 'q1')],
    );

    final vm = SelectQueueViewModel(playbackManager: playback);
    await Future.delayed(Duration.zero);

    when(() => queue.getQueues(filter: any(named: 'filter'))).thenAnswer(
      (_) async => [makeQueue(id: 'q1'), makeQueue(id: 'q2')],
    );

    final queueListener =
        verify(() => queue.addListener(captureAny())).captured.last
            as void Function();

    var notified = false;
    vm.addListener(() => notified = true);

    queueListener();
    await Future.delayed(Duration.zero);

    expect(vm.queues.length, 2);
    expect(notified, isTrue);
  });

  test('selectQueue delegates to queue.switchQueue', () async {
    final vm = await buildViewModel();
    final q = makeQueue(id: 'q1');

    await vm.selectQueue(q);

    verify(() => queue.switchQueue('q1')).called(1);
  });

  test('deleteQueue delegates to queue.deleteQueue', () async {
    final vm = await buildViewModel();
    final q = makeQueue(id: 'q1');

    await vm.deleteQueue(q);

    verify(() => queue.deleteQueue('q1')).called(1);
  });

  test('dispose removes listener: no reload after dispose', () async {
    final vm = await buildViewModel();

    final queueListener =
        verify(() => queue.addListener(captureAny())).captured.last
            as void Function();

    vm.dispose();

    verify(() => queue.removeListener(queueListener)).called(1);
  });
}