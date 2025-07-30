import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/settings/settings_viewmodel.dart';
import 'package:crossonic/utils/exit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _viewModel = SettingsViewModel(
      authRepository: context.read(),
      versionRepository: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = theme.textTheme.bodyMedium!.copyWith(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Home Layout"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(const HomeLayoutRoute()),
          ),
          ListTile(
            title: const Text("Transcoding"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(const TranscodingRoute()),
          ),
          ListTile(
            title: const Text("Replay Gain"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(const ReplayGainRoute()),
          ),
          ListTile(
            title: const Text("Scan"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(const ScanRoute()),
          ),
          if (_viewModel.supportsListenBrainz)
            ListTile(
              title: const Text("ListenBrainz"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => context.router.push(const ListenBrainzRoute()),
            ),
          ListTile(
            title: const Text("Debug"),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.router.push(const DebugRoute()),
          ),
          ListTile(
            title: const Text("About"),
            trailing: const Icon(Icons.info_outline),
            onTap: () async {
              final version = await _viewModel.version;
              if (!context.mounted) return;
              showAboutDialog(
                context: context,
                applicationIcon: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Image.asset(
                      "assets/icon/desktop/crossonic-512.png",
                      cacheHeight: 48 * 2,
                      cacheWidth: 48 * 2,
                      isAntiAlias: true,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                applicationName: "Crossonic",
                applicationVersion: version,
                applicationLegalese:
                    "\u{a9} 2024-${DateTime.now().year} Julian Hofmann",
                children: [
                  const SizedBox(height: 24),
                  const Text(
                      "Crossonic is a cross-platform music player for OpenSubsonic compatible music servers.\n"
                      "It's free software under the AGPL-3.0 license."),
                  const SizedBox(height: 12),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () =>
                          launchUrl(Uri.parse("https://crossonic.org")),
                      child: Text(
                        "Website",
                        style: linkStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => launchUrl(
                          Uri.parse("https://github.com/juho05/crossonic")),
                      child: Text(
                        "GitHub",
                        style: linkStyle,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => launchUrl(
                          Uri.parse("https://crossonic.org/privacy/app")),
                      child: Text(
                        "Privacy Policy",
                        style: linkStyle,
                      ),
                    ),
                  ),
                ],
              );
            },
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
