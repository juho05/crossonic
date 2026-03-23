/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/settings/pages/appimage_settings_viewmodel.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AppImagePage extends StatelessWidget {
  const AppImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium!;
    return ChangeNotifierProvider(
      create: (context) =>
          AppImageSettingsViewModel(appImageRepository: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("AppImage Integration")),
          body: SafeArea(
            child: Consumer<AppImageSettingsViewModel>(
              builder: (context, viewModel, _) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    Row(
                      children: [
                        const Text("Integrated: "),
                        Text(
                          viewModel.integrated == null
                              ? "checking…"
                              : (viewModel.integrated! ? "YES" : "NO"),
                          style: viewModel.integrated != null
                              ? textStyle.copyWith(
                                  color: viewModel.integrated!
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                )
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentGeometry.centerLeft,
                      child: Button(
                        onPressed: viewModel.integrated != null
                            ? () async {
                                final result = await viewModel.integrate();
                                if (!context.mounted) return;
                                toastResult(context, result);
                              }
                            : null,
                        icon: Icons.install_desktop,
                        outlined: viewModel.integrated ?? false,
                        child: Text(
                          (viewModel.integrated ?? false)
                              ? "Re-Integrate"
                              : "Integrate",
                        ),
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
                      "Integrating an AppImage means, …",
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
