import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/settings/pages/debug_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talker_flutter/talker_flutter.dart';

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
    _viewModel = DebugViewModel(settings: context.read());
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
        title: const Text("Debug"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownMenu<LogLevel>(
                  onSelected: (level) {
                    if (level == null) return;
                    _viewModel.update(level: level);
                  },
                  expandedInsets: EdgeInsets.zero,
                  requestFocusOnTap: false,
                  enableSearch: false,
                  initialSelection: _viewModel.level,
                  label: const Text("Log Level"),
                  dropdownMenuEntries: logLevelPriorityList.map((level) {
                    return DropdownMenuEntry<LogLevel>(
                      label:
                          level.name[0].toUpperCase() + level.name.substring(1),
                      value: level,
                    );
                  }).toList(),
                ),
                Button(
                  onPressed: () => context.router.push(const LogsRoute()),
                  icon: Icons.list,
                  darkTonal: true,
                  child: const Text("View Logs"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
