import 'package:auto_route/annotations.dart';
import 'package:crossonic/ui/bpm/bpm_viewmodel.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/refresh_scroll_view.dart';
import 'package:crossonic/ui/common/song_list_sliver.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class BpmPage extends StatefulWidget {
  const BpmPage({super.key});

  @override
  State<BpmPage> createState() => _BpmPageState();
}

class _BpmPageState extends State<BpmPage> {
  late final BpmViewModel _viewModel;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = BpmViewModel(
      subsonic: context.read(),
      audioHandler: context.read(),
    )..nextPage();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return RefreshScrollView(
            onRefresh: () => _viewModel.refresh(),
            controller: _controller,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: RangeSlider(
                        values: _viewModel.bpmRange,
                        divisions: 32,
                        min: 45,
                        max: 205,
                        onChanged: (range) {
                          _viewModel.bpmRange = range;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${_viewModel.bpmRange.start < 50 ? "0" : _viewModel.bpmRange.start.round()} ≤",
                          ),
                          Text(
                            "≥ ${_viewModel.bpmRange.end > 200 ? "∞" : _viewModel.bpmRange.end.round()}",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Button(
                        icon: Icons.play_arrow,
                        onPressed: () {
                          _viewModel.play();
                        },
                        child: const Text("Play"),
                      ),
                      Button(
                        icon: Icons.shuffle,
                        onPressed: () {
                          _viewModel.shuffle();
                        },
                        child: const Text("Shuffle"),
                      ),
                      Button(
                        icon: Icons.playlist_play,
                        outlined: true,
                        onPressed: () {
                          _viewModel.addToQueue(true);
                          Toast.show(context, "Added songs to priority queue");
                        },
                        child: const Text("Prio. Queue"),
                      ),
                      Button(
                        icon: Icons.playlist_add,
                        outlined: true,
                        onPressed: () {
                          _viewModel.addToQueue(false);
                          Toast.show(context, "Added songs to queue");
                        },
                        child: const Text("Queue"),
                      ),
                    ],
                  ),
                ),
              ),
              SongListSliver(
                songs: _viewModel.songs,
                fetchStatus: _viewModel.status,
                showYear: false,
                showBpm: true,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onScroll() {
    if (_isBottom) _viewModel.nextPage();
  }

  bool get _isBottom {
    if (!_controller.hasClients) return false;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.offset;
    return currentScroll >= (maxScroll * 0.8);
  }
}
