import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/song.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/shimmer.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/queue/queue_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final shimmerGradient = Shimmer.createGradient(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Queue")),
      body: Shimmer(
        linearGradient: shimmerGradient,
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final theme = Theme.of(context);

            Widget songListItem(int i, Song? s, {bool floating = false}) {
              if (s == null) {
                return Padding(
                  key: ValueKey("$i-loading"),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: const ShimmerLoading(child: Material()),
                  ),
                );
              }
              return SongListItem(
                song: s,
                key: ValueKey("$i-${s.id}"),
                enableLongPressReorder: !floating,
                opaque: floating,
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
                      padding: const EdgeInsets.only(left: 8),
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
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text("Inactive playback"),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Priority queue (${_viewModel.prioQueueLength})",
                              style: theme.textTheme.headlineSmall!.copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (_viewModel.prioQueueLength > 0)
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
                          if (_viewModel.prioQueueLength > 0)
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
                              icon: const Icon(Icons.delete_sweep_outlined),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SliverReorderableList(
                  itemCount:
                      _viewModel.prioQueueLength + 1 + _viewModel.queueLength,
                  itemExtentBuilder: (index, dimensions) {
                    if (index == _viewModel.prioQueueLength) return 40;
                    return ClickableListItem.verticalExtent;
                  },
                  proxyDecorator: (child, index, animation) {
                    final song = index < _viewModel.prioQueueLength
                        ? _viewModel.getPrioSong(index)
                        : _viewModel.getSong(
                            index - 1 - _viewModel.prioQueueLength,
                          );
                    return songListItem(index, song, floating: true);
                  },
                  itemBuilder: (context, i) {
                    if (i < _viewModel.prioQueueLength) {
                      final s = _viewModel.getPrioSong(i);
                      return songListItem(i, s);
                    }
                    if (i == _viewModel.prioQueueLength) {
                      return Padding(
                        key: _queueSeparatorKey,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Queue (${_viewModel.queueLength})",
                                style: theme.textTheme.headlineSmall!.copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                            if (_viewModel.queueLength > 0)
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
                            if (_viewModel.queueLength > 0)
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
                                icon: const Icon(Icons.delete_sweep_outlined),
                              ),
                          ],
                        ),
                      );
                    }
                    final s = _viewModel.getSong(
                      i - 1 - _viewModel.prioQueueLength,
                    );
                    return songListItem(i, s);
                  },
                  onReorderStart: (_) {
                    HapticFeedback.lightImpact();
                  },
                  onReorder: _viewModel.reorder,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
