import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/subsonic/models/lyrics.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/lyrics/lyrics_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

@RoutePage()
class LyricsPage extends StatefulWidget {
  const LyricsPage({super.key});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late final LyricsViewModel _viewModel;

  // 0.0 (top) - 1.0 (bottom) current line position
  static const double _bias = 0.3;

  final _scrollController = ScrollController();
  final _listController = ListController();

  StreamSubscription? _selectedLineSub;

  @override
  void initState() {
    super.initState();
    _viewModel = LyricsViewModel(
      subsonic: context.read(),
      audioHandler: context.read(),
    );

    Lyrics? previousLyrics;
    _selectedLineSub = _viewModel.selectedLine.listen((event) {
      if (previousLyrics != null && previousLyrics != _viewModel.lyrics) {
        _scrollController.jumpTo(0);
        previousLyrics = _viewModel.lyrics;
      }
      _animateToCurrentLine();
    });
  }

  void _animateToCurrentLine() {
    Future.delayed(const Duration(milliseconds: 50), () {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (_viewModel.syncedMode) {
          if (_viewModel.selectedLine.value == null) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            _listController.animateToItem(
              index: _viewModel.selectedLine.value!,
              alignment: _bias,
              scrollController: _scrollController,
              duration: (estimatedDistance) =>
                  const Duration(milliseconds: 300),
              curve: (estimatedDistance) => Curves.easeInOut,
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _selectedLineSub?.cancel();
    _viewModel.dispose();
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Lyrics"),
            forceMaterialTransparency: true,
            actions: [
              if (_viewModel.supportsSync && !_viewModel.syncedMode)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Button(
                    onPressed: () => _viewModel.syncedMode = true,
                    icon: Icons.access_time,
                    outlined: true,
                    child: const Text("Sync"),
                  ),
                )
              else if (_viewModel.lyrics != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _viewModel.syncedMode ? "SYNCED" : "UNSYNCED",
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (_viewModel.status == FetchStatus.failure) {
                  return const Center(child: Icon(Icons.wifi_off));
                }
                if (_viewModel.status != FetchStatus.success) {
                  return const Center(
                    child: CircularProgressIndicator.adaptive(),
                  );
                }
                if (_viewModel.currentSong == null) {
                  return const Center(child: Text("No active song"));
                }
                if (_viewModel.lyrics == null ||
                    _viewModel.lyrics!.lines.isEmpty) {
                  return const Center(child: Text("No lyrics"));
                }
                final textTheme = Theme.of(context).textTheme.headlineMedium!;
                final normalTextTheme = textTheme.copyWith(
                  fontSize: constraints.maxWidth >= 1000 ? 24 : 18,
                );
                final highlightedTextTheme = textTheme.copyWith(
                  fontSize: constraints.maxWidth >= 1000 ? 28 : 22,
                  fontWeight: FontWeight.bold,
                );
                final highlightedEmojiTextTheme = textTheme.copyWith(
                  fontSize: constraints.maxWidth >= 1000 ? 32 : 26,
                  fontWeight: FontWeight.w900,
                );
                return NotificationListener<UserScrollNotification>(
                  onNotification: (notification) {
                    if (notification.direction == ScrollDirection.idle) {
                      return false;
                    }
                    _viewModel.syncedMode = false;
                    return true;
                  },
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(8),
                        sliver: SuperSliverList.builder(
                          listController: _listController,
                          itemCount: _viewModel.lyrics!.lines.length,
                          itemBuilder: (context, index) {
                            final line = _viewModel.lyrics!.lines[index];
                            return StreamBuilder(
                              stream: _viewModel.selectedLine.distinct(
                                (previous, next) =>
                                    (previous == index) == (next == index),
                              ),
                              builder: (context, snapshot) {
                                final isCurrent =
                                    _viewModel.syncedMode &&
                                    snapshot.data == index;
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: !isCurrent ? 8 : 0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Material(
                                        child: InkWell(
                                          onTap:
                                              line.start != null &&
                                                  _viewModel.supportsSync
                                              ? () {
                                                  _viewModel.seek(line.start!);
                                                }
                                              : null,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.0,
                                              horizontal: line.text.isNotEmpty
                                                  ? 12
                                                  : 50,
                                            ),
                                            child: Text(
                                              line.text.isNotEmpty ||
                                                      !_viewModel.supportsSync
                                                  ? line.text
                                                  : "♪♫♪",
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              style: isCurrent
                                                  ? (line.text.isEmpty &&
                                                            _viewModel
                                                                .supportsSync
                                                        ? highlightedEmojiTextTheme
                                                        : highlightedTextTheme)
                                                  : normalTextTheme,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
