part of 'queue_cubit.dart';

class QueueState extends Equatable {
  final List<Media> priorityQueue;
  final List<Media> queue;
  final Media? current;

  const QueueState({
    required this.priorityQueue,
    required this.queue,
    required this.current,
  });

  @override
  List<Object?> get props => [priorityQueue, queue, current];
}
