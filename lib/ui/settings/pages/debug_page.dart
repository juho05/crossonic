import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/help_button.dart';
import 'package:crossonic/ui/common/section_header.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/settings/pages/debug_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

@RoutePage()
class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  late final DebugViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DebugViewModel(
      settings: context.read(),
      coverRepo: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Debug")),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: SectionHeader(text: "Logging"),
              ),
              DropdownMenu<Level>(
                onSelected: (level) {
                  if (level == null) return;
                  _viewModel.level = level;
                },
                expandedInsets: EdgeInsets.zero,
                requestFocusOnTap: false,
                enableSearch: false,
                initialSelection: _viewModel.level,
                label: const Text("Level"),
                dropdownMenuEntries: [
                  const DropdownMenuEntry<Level>(
                    label: "OFF",
                    value: Level.off,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Fatal",
                    value: Level.fatal,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Error",
                    value: Level.error,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Warning",
                    value: Level.warning,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Info",
                    value: Level.info,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Debug",
                    value: Level.debug,
                  ),
                  const DropdownMenuEntry<Level>(
                    label: "Trace",
                    value: Level.trace,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Button(
                    onPressed: () {
                      context.pushRoute(const LogsRoute());
                    },
                    darkTonal: true,
                    icon: Icons.list,
                    child: const Text("View logs"),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SectionHeader(text: "Actions"),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Button(
                  onPressed: () async {
                    await _viewModel.clearCoverCache();
                    if (!context.mounted) return;
                    Toast.show(context, "Successfully cleared cover cache!");
                  },
                  darkTonal: true,
                  icon: Icons.image_not_supported_outlined,
                  child: const Text("Clear cover cache"),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SectionHeader(
                  text: "Workarounds",
                  trailing: [
                    HelpButton(
                      dialogTitle: "Workarounds",
                      dialogContentText:
                          "Workarounds are options that can be enabled"
                          " to fix hardware/system specific issues/quirks.\nOnly enable a"
                          " workaround if you are actually experiencing an issue"
                          " and the workaround fixes it.\n\nUsually all workarounds should"
                          " stay disabled.\n"
                          "Always read the description of a workaround before enabling it.",
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                onChanged: (value) {
                  _viewModel.stopIsPause = value;
                },
                title: const Row(
                  children: [
                    Text("Treat stop as pause"),
                    HelpButton(
                      dialogTitle: "Treat stop as pause",
                      dialogContentText:
                          "Some devices send a stop command to the app"
                          " in some situation when they actually should send a pause command.\n"
                          "This causes the playback to completely stop and the queue to be cleared.\n\n"
                          "With this option enabled all stop commands will be interpreted as pause commands.\nThis will prevent actual"
                          " stop commands from working (i.e. when pressing the stop key on your keyboard or\n"
                          "when pressing the rectangle button in the media notification).",
                    ),
                  ],
                ),
                value: _viewModel.stopIsPause,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Button(
                    enabled: _viewModel.stopIsPause,
                    onPressed: () {
                      _viewModel.resetWorkarounds();
                    },
                    outlined: true,
                    icon: Icons.clear,
                    child: const Text("Disable all workarounds"),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
