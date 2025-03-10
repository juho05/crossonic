import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
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
      appBar: AppBar(
        title: Text("Queue"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final theme = Theme.of(context);
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
                if (_viewModel.currentSong != null)
                  SongListItem(
                    id: _viewModel.currentSong!.id,
                    title: _viewModel.currentSong!.title,
                    artist: _viewModel.currentSong!.displayArtist,
                    coverId: _viewModel.currentSong!.coverId,
                    duration: _viewModel.currentSong!.duration,
                    year: _viewModel.currentSong!.year,
                    onAddToQueue: (priority) {
                      _viewModel.addSongToQueue(
                          _viewModel.currentSong!, priority);
                      Toast.show(context,
                          "Added '${_viewModel.currentSong!.title}' to ${priority ? "priority " : ""}queue");
                    },
                    onAddToPlaylist: () {
                      AddToPlaylistDialog.show(
                          context,
                          _viewModel.currentSong!.title,
                          [_viewModel.currentSong!]);
                    },
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
                          style: theme.textTheme.headlineSmall!
                              .copyWith(fontSize: 20),
                        ),
                      ),
                      if (_viewModel.priorityQueue.isNotEmpty)
                        IconButton(
                          onPressed: () async {
                            if (!(await ConfirmationDialog.showCancel(
                                context, "Shuffle priority queue?"))) {
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
                                context, "Clear priority queue?"))) {
                              return;
                            }
                            _viewModel.clearPriorityQueue();
                          },
                          icon: const Icon(Icons.delete_outline),
                        )
                    ],
                  ),
                ),
              ],
            ),
            onReorder: _viewModel.reorder,
            children: [
              ...List<Widget>.generate(_viewModel.priorityQueue.length, (i) {
                final s = _viewModel.priorityQueue[i];
                return SongListItem(
                  id: s.id,
                  title: s.title,
                  duration: s.duration,
                  key: ValueKey("$i${s.coverId}"),
                  reorderIndex: i,
                  disablePlaybackStatus: true,
                  coverId: s.coverId,
                  artist: s.displayArtist,
                  year: s.year,
                  removeButton: true,
                  onRemove: () {
                    _viewModel.remove(i);
                  },
                  onTap: (_) {
                    _viewModel.goto(i);
                  },
                  onAddToQueue: (priority) {
                    _viewModel.addSongToQueue(s, priority);
                    Toast.show(context,
                        "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                  },
                  onAddToPlaylist: () {
                    AddToPlaylistDialog.show(context, s.title, [s]);
                  },
                );
              }),
              Padding(
                key: _queueSeparatorKey,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Queue (${_viewModel.queue.length})",
                        style: theme.textTheme.headlineSmall!
                            .copyWith(fontSize: 20),
                      ),
                    ),
                    if (_viewModel.queue.isNotEmpty)
                      IconButton(
                        onPressed: () async {
                          if (!(await ConfirmationDialog.showCancel(
                              context, "Shuffle queue?"))) {
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
                              context, "Clear queue?"))) {
                            return;
                          }
                          _viewModel.clearQueue();
                        },
                        icon: const Icon(Icons.delete_outline),
                      )
                  ],
                ),
              ),
              ...List<Widget>.generate(
                _viewModel.queue.length,
                (i) {
                  final s = _viewModel.queue[i];
                  return SongListItem(
                    key: ValueKey(
                        "${i + _viewModel.priorityQueue.length + 1}${s.coverId}"),
                    reorderIndex: i + _viewModel.priorityQueue.length + 1,
                    disablePlaybackStatus: true,
                    id: s.id,
                    title: s.title,
                    artist: s.displayArtist,
                    coverId: s.coverId,
                    duration: s.duration,
                    year: s.year,
                    removeButton: true,
                    onRemove: () {
                      _viewModel
                          .remove(i + _viewModel.priorityQueue.length + 1);
                    },
                    onTap: (_) {
                      _viewModel.goto(i + _viewModel.priorityQueue.length + 1);
                    },
                    onAddToQueue: (priority) {
                      _viewModel.addSongToQueue(s, priority);
                      Toast.show(context,
                          "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                    },
                    onAddToPlaylist: () {
                      AddToPlaylistDialog.show(context, s.title, [s]);
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
