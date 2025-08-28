import 'package:auto_route/annotations.dart';
import 'package:crossonic/ui/settings/pages/logs/log_message_list_item.dart';
import 'package:crossonic/ui/settings/pages/logs/logs_page_viewmodel.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Logs"),
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
                            const Text("Current"),
                          ],
                        ),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          // TODO
                        },
                      )
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverToBoxAdapter(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        decoration: InputDecoration(
                          labelText: "Search",
                          icon: const Icon(Icons.search),
                          suffixIcon: _viewModel.searchText.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchFocus.unfocus();
                                    _viewModel.clearSearch();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (query) {
                          _viewModel.search(query);
                        },
                        onTapOutside: (_) => _searchFocus.unfocus(),
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
    _searchController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }
}
