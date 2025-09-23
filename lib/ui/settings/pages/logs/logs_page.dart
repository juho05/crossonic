import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/search_input.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:crossonic/ui/settings/pages/logs/log_message_list_item.dart';
import 'package:crossonic/ui/settings/pages/logs/logs_page_viewmodel.dart';
import 'package:crossonic/utils/format.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

@RoutePage()
class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final ScrollController _scrollController = ScrollController();

  late final LogsPageViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LogsPageViewModel(
        settingsRepository: context.read(), logRepository: context.read());

    _scrollController.addListener(() {
      _viewModel.enableMessageStream(_scrollController.position.pixels < 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shareButton =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs"),
        actions: [
          // the Android share dialog does not allow saving the file
          if (!shareButton || (!kIsWeb && Platform.isAndroid))
            MenuButton(
              icon: const Icon(Icons.save_alt),
              tooltip: "Save log",
              options: [
                ContextMenuOption(
                  title: "Save full log",
                  onSelected: () async {
                    final result = await _viewModel.saveLog(filtered: false);
                    if (!context.mounted) return;
                    if (result is Ok && !result.tryValue!) {
                      // user canceled save
                      return;
                    }
                    toastResult(context, result,
                        successMsg: "Successfully saved log!");
                  },
                ),
                ContextMenuOption(
                  title: "Save filtered log",
                  onSelected: () async {
                    final result = await _viewModel.saveLog(filtered: true);
                    if (!context.mounted) return;
                    if (result is Ok && !result.tryValue!) {
                      // user canceled save
                      return;
                    }
                    toastResult(context, result,
                        successMsg: "Successfully saved log!");
                  },
                ),
              ],
            ),
          if (shareButton)
            MenuButton(
              icon: const Icon(Icons.share),
              tooltip: "Share log",
              options: [
                ContextMenuOption(
                  title: "Share full log",
                  onSelected: () async {
                    final result = await _viewModel.shareLog(filtered: false);
                    if (!context.mounted) return;
                    if (result is Ok && !result.tryValue!) {
                      // user canceled share
                      return;
                    }
                    toastResult(context, result,
                        successMsg: "Successfully shared log!");
                  },
                ),
                ContextMenuOption(
                  title: "Share filtered log",
                  onSelected: () async {
                    final result = await _viewModel.shareLog(filtered: true);
                    if (!context.mounted) return;
                    if (result is Ok && !result.tryValue!) {
                      // user canceled share
                      return;
                    }
                    toastResult(context, result,
                        successMsg: "Successfully shared log!");
                  },
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList.list(
                    children: [
                      ListTile(
                        title: Row(
                          children: [
                            Text(
                              "Session:",
                              style: textTheme.bodyMedium!
                                  .copyWith(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Text(_viewModel.sessionTime == Log.sessionStartTime
                                ? "Current"
                                : formatDateTime(_viewModel.sessionTime)),
                          ],
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () async {
                          final chosenSession = await context.router
                              .push<DateTime>(ChooseLogSessionRoute(
                                  highlight: _viewModel.sessionTime));
                          if (chosenSession == null) return;
                          await _viewModel.changeSessionTime(chosenSession);
                          _scrollController.jumpTo(0);
                        },
                      )
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverToBoxAdapter(
                      child: SearchInput(
                        onSearch: _viewModel.search,
                        debounce: const Duration(milliseconds: 250),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverToBoxAdapter(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final shortNames = constraints.maxWidth < 640;
                        return SegmentedButton(
                          emptySelectionAllowed: true,
                          multiSelectionEnabled: true,
                          showSelectedIcon: constraints.maxWidth > 325,
                          onSelectionChanged: (levels) {
                            _viewModel.enabledLevels = levels;
                          },
                          segments: <ButtonSegment<Level>>[
                            ButtonSegment(
                                value: Level.trace,
                                label: Text(shortNames ? "T" : "Trace"),
                                tooltip: "Show trace"),
                            ButtonSegment(
                                value: Level.debug,
                                label: Text(shortNames ? "D" : "Debug"),
                                tooltip: "Show debug"),
                            ButtonSegment(
                                value: Level.info,
                                label: Text(shortNames ? "I" : "Info"),
                                tooltip: "Show info"),
                            ButtonSegment(
                                value: Level.warning,
                                label: Text(shortNames ? "W" : "Warning"),
                                tooltip: "Show warnings"),
                            ButtonSegment(
                                value: Level.error,
                                label: Text(shortNames ? "E" : "Error"),
                                tooltip: "Show errors"),
                            ButtonSegment(
                                value: Level.fatal,
                                label: Text(shortNames ? "F" : "Fatal"),
                                tooltip: "Show fatal"),
                          ],
                          selected: _viewModel.enabledLevels,
                        );
                      }),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverFixedExtentList.builder(
                      itemBuilder: (context, index) => LogMessageListItem(
                        msg: _viewModel.logMessages[
                            _viewModel.logMessages.length - 1 - index],
                      ),
                      itemExtent: LogMessageListItem.verticalExtent,
                      itemCount: _viewModel.logMessages.length,
                    ),
                  )
                ],
              );
            }),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
