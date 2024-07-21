import 'package:crossonic/features/queue/state/queue_cubit.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:crossonic/components/app_bar.dart';
import 'package:crossonic/components/confirmation.dart';
import 'package:crossonic/components/song.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QueuePage extends StatefulWidget {
  const QueuePage({super.key});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final GlobalKey _queueSeparatorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QueueCubit(context.read<CrossonicAudioHandler>().mediaQueue),
      child: Scaffold(
        appBar: createAppBar(context, "Queue"),
        body: BlocBuilder<QueueCubit, QueueState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            final queue = context.read<QueueCubit>();
            return ReorderableListView(
              buildDefaultDragHandles: false,
              header: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      "Current",
                      style:
                          theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
                    ),
                  ),
                  if (state.current != null)
                    Song(
                      song: state.current!,
                      leadingItem: SongLeadingItem.cover,
                      showArtist: true,
                      showYear: true,
                      showAddToQueue: false,
                      showGotoAlbum: false,
                      showGotoArtist: false,
                    ),
                  if (state.current == null) const Text("Inactive playback"),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Priority queue (${state.priorityQueue.length})",
                            style: theme.textTheme.headlineSmall!
                                .copyWith(fontSize: 20),
                          ),
                        ),
                        if (state.priorityQueue.isNotEmpty)
                          IconButton(
                            onPressed: () async {
                              if (!(await ConfirmationDialog.showCancel(
                                  context, "Shuffle priority queue?"))) {
                                return;
                              }
                              queue.shufflePriorityQueue();
                            },
                            icon: const Icon(Icons.shuffle),
                          ),
                        if (state.priorityQueue.isNotEmpty)
                          IconButton(
                            onPressed: () async {
                              if (!(await ConfirmationDialog.showCancel(
                                  context, "Clear priority queue?"))) {
                                return;
                              }
                              queue.clearPriorityQueue();
                            },
                            icon: const Icon(Icons.delete_outline),
                          )
                      ],
                    ),
                  ),
                ],
              ),
              onReorder: queue.reorder,
              children: [
                ...List<Widget>.generate(
                  state.priorityQueue.length,
                  (i) => Song(
                    key: ValueKey(i),
                    reorderIndex: i,
                    song: state.priorityQueue[i],
                    leadingItem: SongLeadingItem.cover,
                    showArtist: true,
                    showYear: true,
                    showGotoAlbum: false,
                    showGotoArtist: false,
                    showAddToQueue: false,
                    onRemove: () {
                      queue.remove(i);
                    },
                    onTap: () {
                      queue.goto(i);
                    },
                  ),
                ),
                Padding(
                  key: _queueSeparatorKey,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Queue (${state.queue.length})",
                          style: theme.textTheme.headlineSmall!
                              .copyWith(fontSize: 20),
                        ),
                      ),
                      if (state.queue.isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            if (!(await ConfirmationDialog.showCancel(
                                context, "Shuffle queue?"))) {
                              return;
                            }
                            queue.shuffleQueue();
                          },
                          icon: const Icon(Icons.shuffle),
                        ),
                      if (state.queue.isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            if (!(await ConfirmationDialog.showCancel(
                                context, "Clear queue?"))) {
                              return;
                            }
                            queue.clearQueue();
                          },
                          icon: const Icon(Icons.delete_outline),
                        )
                    ],
                  ),
                ),
                ...List<Widget>.generate(
                  state.queue.length,
                  (i) {
                    return Song(
                      key: ValueKey(i + state.priorityQueue.length + 1),
                      reorderIndex: i + state.priorityQueue.length + 1,
                      song: state.queue[i],
                      leadingItem: SongLeadingItem.cover,
                      showArtist: true,
                      showYear: true,
                      showGotoAlbum: false,
                      showGotoArtist: false,
                      showAddToQueue: false,
                      onRemove: () {
                        queue.remove(i + state.priorityQueue.length + 1);
                      },
                      onTap: () {
                        queue.goto(i + state.priorityQueue.length + 1);
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
