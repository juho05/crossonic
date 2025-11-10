import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/queue/queue_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final GlobalKey _queueSeparatorKey = GlobalKey();
  late final QueueViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = QueueViewModel(audioHandler: context.read());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Queue")),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final theme = Theme.of(context);

          Widget songListItem(int i, Song s, {bool opaque = false}) {
            return SongListItem(
              song: s,
              opaque: opaque,
              key: ValueKey("$i${s.coverId}"),
              reorderIndex: i,
              showDragHandle: true,
              showPlaybackStatus: false,
              showRemoveButton: true,
              onRemove: () {
                _viewModel.remove(i);
              },
              onTap: (_) {
                _viewModel.goto(i);
              },
            );
          }

          return CustomScrollView(
            slivers: [
              SliverList.list(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Current",
                      style: theme.textTheme.headlineSmall!.copyWith(
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (_viewModel.currentSong != null)
                    SongListItem(
                      key: ValueKey("current-${_viewModel.currentSong!.id}"),
                      song: _viewModel.currentSong!,
                    ),
                  if (_viewModel.currentSong == null)
                    const Text("Inactive playback"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Priority queue (${_viewModel.priorityQueue.length})",
                            style: theme.textTheme.headlineSmall!.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (_viewModel.priorityQueue.isNotEmpty)
                          IconButton(
                            onPressed: () async {
                              if (!(await ConfirmationDialog.showCancel(
                                context,
                                "Shuffle priority queue?",
                              ))) {
                                return;
                              }
                              _viewModel.shufflePriorityQueue();
                            },
                            icon: const Icon(Icons.shuffle),
                          ),
                        if (_viewModel.priorityQueue.isNotEmpty)
                          IconButton(
                            onPressed: () async {
                              if (!(await ConfirmationDialog.showCancel(
                                context,
                                "Clear priority queue?",
                              ))) {
                                return;
                              }
                              _viewModel.clearPriorityQueue();
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SliverReorderableList(
                itemCount:
                    _viewModel.priorityQueue.length +
                    1 +
                    _viewModel.queue.length,
                itemExtentBuilder: (index, dimensions) {
                  if (index == _viewModel.priorityQueue.length) return 40;
                  return ClickableListItem.verticalExtent;
                },
                proxyDecorator: (child, index, animation) {
                  final song = index < _viewModel.priorityQueue.length
                      ? _viewModel.priorityQueue[index]
                      : _viewModel.queue[index -
                            1 -
                            _viewModel.priorityQueue.length];
                  return songListItem(index, song, opaque: true);
                },
                itemBuilder: (context, i) {
                  if (i < _viewModel.priorityQueue.length) {
                    final s = _viewModel.priorityQueue[i];
                    return songListItem(i, s);
                  }
                  if (i == _viewModel.priorityQueue.length) {
                    return Padding(
                      key: _queueSeparatorKey,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Queue (${_viewModel.queue.length})",
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (_viewModel.queue.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                if (!(await ConfirmationDialog.showCancel(
                                  context,
                                  "Shuffle queue?",
                                ))) {
                                  return;
                                }
                                _viewModel.shuffleQueue();
                              },
                              icon: const Icon(Icons.shuffle),
                            ),
                          if (_viewModel.queue.isNotEmpty)
                            IconButton(
                              onPressed: () async {
                                if (!(await ConfirmationDialog.showCancel(
                                  context,
                                  "Clear queue?",
                                ))) {
                                  return;
                                }
                                _viewModel.clearQueue();
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ),
                    );
                  }
                  final s =
                      _viewModel.queue[i - 1 - _viewModel.priorityQueue.length];
                  return songListItem(i, s);
                },
                onReorder: _viewModel.reorder,
              ),
            ],
          );
        },
      ),
    );
  }
}
