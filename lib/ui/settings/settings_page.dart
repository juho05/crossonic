import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/settings/settings_viewmodel.dart';
import 'package:crossonic/utils/exit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final SettingsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SettingsViewModel(authRepository: context.read());
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
        title: Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Transcoding"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(TranscodingRoute()),
          ),
          ListTile(
            title: const Text("Replay Gain"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(ReplayGainRoute()),
          ),
          ListTile(
            title: const Text("Scan"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(ScanRoute()),
          ),
          if (_viewModel.supportsListenBrainz)
            ListTile(
              title: const Text("ListenBrainz"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.router.push(ListenBrainzRoute()),
            ),
          ListTile(
            title: const Text("Debug"),
            trailing: const Icon(Icons.bug_report),
            onTap: () => context.router.push(DebugRoute()),
          ),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              return ListTile(
                title: const Text("Logout"),
                trailing: const Icon(Icons.logout),
                onTap: !_viewModel.loggingOut
                    ? () async {
                        final confirmed = await ConfirmationDialog.showYesNo(
                            context,
                            title: "Logout?");
                        if (confirmed ?? false) {
                          await _viewModel.logout();
                        }
                      }
                    : null,
              );
            },
          ),
          if (!kIsWeb &&
              (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
            ListTile(
              title: const Text("Exit"),
              trailing: const Icon(Icons.close),
              onTap: () async {
                final confirmed = await ConfirmationDialog.showYesNo(context,
                    title: "Exit the app?");
                if (confirmed ?? false) {
                  await exitApp();
                }
              },
            ),
        ],
      ),
    );
  }
}
