/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/ui/settings/pages/version_checking_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum VersionCheckNowDialogOptions { close, view, install }

@RoutePage()
class VersionCheckingPage extends StatelessWidget {
  const VersionCheckingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    return ChangeNotifierProvider(
      create: (context) => VersionCheckingViewModel(
        settings: context.read<SettingsRepository>().versionChecking,
        repository: context.read(),
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Version Checking")),
          body: SafeArea(
            child: Consumer<VersionCheckingViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    SwitchListTile(
                      onChanged: (value) {
                        viewModel.updateEnabled(value);
                      },
                      value: viewModel.enabled,
                      title: const Text("Check for new versions"),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        enabled: !viewModel.checking,
                        onPressed: () async {
                          final result = await viewModel.check();
                          if (!context.mounted) return;
                          switch (result) {
                            case Err():
                              toastResult(context, result);
                              return;
                            case Ok():
                          }
                          final current = result.value.current;
                          final latest = result.value.latest;
                          if (latest == null) return;
                          if (latest > current) {
                            final actions = [
                              AdaptiveDialogAction(
                                onPressed: () => Navigator.pop(
                                  context,
                                  VersionCheckNowDialogOptions.view,
                                ),
                                child: const Text("View"),
                              ),
                              if (AutoUpdateRepository.autoUpdatesSupported)
                                AdaptiveDialogAction(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    VersionCheckNowDialogOptions.install,
                                  ),
                                  child: const Text("Install"),
                                ),
                              AdaptiveDialogAction(
                                onPressed: () => Navigator.pop(
                                  context,
                                  VersionCheckNowDialogOptions.close,
                                ),
                                child: const Text("Close"),
                              ),
                            ];
                            showAdaptiveDialog<VersionCheckNowDialogOptions>(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return AlertDialog.adaptive(
                                  title: const Text("New version available"),
                                  content: Text(
                                    "Current: v$current\nLatest: v$latest",
                                  ),
                                  actions: actions,
                                );
                              },
                            ).then((choice) async {
                              if (!context.mounted) return;
                              switch (choice) {
                                case VersionCheckNowDialogOptions.close || null:
                                  break;
                                case VersionCheckNowDialogOptions.view:
                                  launchUrl(
                                    Uri.https(
                                      "github.com",
                                      "/juho05/crossonic/releases",
                                    ),
                                  );
                                case VersionCheckNowDialogOptions.install:
                                  context.router.push(
                                    const InstallUpdateRoute(),
                                  );
                              }
                            });
                          } else {
                            Toast.show(
                              context,
                              "You are already running the latest version: v$current!",
                            );
                          }
                        },
                        icon: Icons.update,
                        darkTonal: true,
                        child: viewModel.checking
                            ? const Text("Checking…")
                            : const Text("Check now"),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Enabling version checking will periodically contact the GitHub API to check for new versions of Crossonic"
                      "and display a dialog on startup if a new version is found.",
                      style: textStyle.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(180),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
