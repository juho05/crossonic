import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:crossonic/repositories/api/models/models.dart';
import 'package:crossonic/services/audio_player/media_queue.dart';
import 'package:equatable/equatable.dart';

part 'queue_state.dart';

class QueueCubit extends Cubit<QueueState> {
  final MediaQueue _queue;
  late final StreamSubscription _queueSubscription;
  QueueCubit(MediaQueue queue)
      : _queue = queue,
        super(const QueueState(
          current: null,
          priorityQueue: [],
          queue: [],
        )) {
    _queueSubscription = _queue.current.listen(_onCurrentChanged);
  }

  void _onCurrentChanged(CurrentMedia? current) {
    _emitState(current);
  }

  void reorder(int oldIndex, int newIndex) {
    final Media song;
    if (_isPriorityQueue(oldIndex)) {
      song = state.priorityQueue.removeAt(oldIndex);
      _queue.removeFromPriorityQueue(oldIndex);
    } else if (_isQueue(oldIndex)) {
      song = state.queue[oldIndex - state.priorityQueue.length - 1];
      _queue.remove(_toQueueIndex(oldIndex));
    } else {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex--;
    }
    if (_isPriorityQueue(newIndex - 1)) {
      _queue.insertIntoPriorityQueue(newIndex, song);
    } else if (_isQueue(newIndex)) {
      _queue.insert(_toQueueIndex(newIndex), song);
    }
    _emitState(_queue.current.value);
  }

  void remove(int index) {
    if (_isPriorityQueue(index)) {
      _queue.removeFromPriorityQueue(index);
    } else if (_isQueue(index)) {
      _queue.remove(_toQueueIndex(index));
    }
    _emitState(_queue.current.value);
  }

  void goto(int index) {
    if (_isPriorityQueue(index)) {
      _queue.gotoPriorityQueue(index);
    } else if (_isQueue(index)) {
      _queue.goto(_toQueueIndex(index));
    }
    // _emitState called by _onCurrentChanged
  }

  void _emitState(CurrentMedia? current) {
    if (current == null) {
      emit(const QueueState(priorityQueue: [], queue: [], current: null));
      return;
    }
    emit(QueueState(
      current: current.item,
      priorityQueue: _queue.priorityQueue.toList(),
      queue: current.index + 1 < _queue.length
          ? _queue.queue.sublist(current.index + 1)
          : [],
    ));
  }

  int _toQueueIndex(int index) {
    index -= state.priorityQueue.length + 1;
    return _queue.current.value!.index + index + 1;
  }

  bool _isPriorityQueue(int index) => index < state.priorityQueue.length;
  bool _isQueue(int index) => index > state.priorityQueue.length;

  @override
  Future<void> close() {
    _queueSubscription.cancel();
    return super.close();
  }
}
