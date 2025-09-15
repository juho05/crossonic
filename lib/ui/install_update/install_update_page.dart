import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/data/services/restart/restart.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/install_update/install_update_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class InstallUpdatePage extends StatelessWidget {
  const InstallUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Install Update"),
      ),
      body: SafeArea(
        child: Builder(builder: (context) {
          if (!AutoUpdateRepository.autoUpdatesSupported) {
            return const Center(
              child: Text(
                  "Auto updates are not supported on this platform/build."),
            );
          }

          return ChangeNotifierProvider(
            create: (context) => InstallUpdateViewModel(
              autoUpdateRepository: context.read(),
            ),
            builder: (context, child) => Consumer<InstallUpdateViewModel>(
              builder: (context, viewModel, _) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    spacing: 16,
                    children: [
                      if (viewModel.status ==
                              AutoUpdateStatus.checkingVersion ||
                          viewModel.status == AutoUpdateStatus.installing)
                        const SizedBox.square(
                          dimension: 64,
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      if (viewModel.status == AutoUpdateStatus.downloading)
                        StreamBuilder(
                            stream: viewModel.downloadProgress,
                            builder: (context, snapshot) {
                              final progress = snapshot.data;
                              return SizedBox.square(
                                dimension: 64,
                                child: Stack(
                                  alignment: Alignment.center,
                                  fit: StackFit.expand,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                    ),
                                    if (progress != null)
                                      Center(
                                        child: Text(
                                          "${(progress * 100).round()} %",
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      )
                                  ],
                                ),
                              );
                            }),
                      if (viewModel.status == AutoUpdateStatus.initial)
                        const Icon(
                          Icons.arrow_circle_down,
                          size: 64,
                        ),
                      if (viewModel.status == AutoUpdateStatus.success)
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                        ),
                      if (viewModel.status == AutoUpdateStatus.failure)
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                        ),
                      Text(
                        switch (viewModel.status) {
                          AutoUpdateStatus.initial =>
                            "Click the button below to install the latest version.",
                          AutoUpdateStatus.checkingVersion =>
                            "Checking version...",
                          AutoUpdateStatus.downloading => "Downloading…",
                          AutoUpdateStatus.installing => "Installing…",
                          AutoUpdateStatus.success => "Update successful!",
                          AutoUpdateStatus.failure => "Update failed!",
                        },
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (viewModel.status == AutoUpdateStatus.initial ||
                          viewModel.status == AutoUpdateStatus.failure)
                        Button(
                          onPressed: () {
                            viewModel.installUpdate();
                          },
                          child: Text(
                              viewModel.status == AutoUpdateStatus.failure
                                  ? "Retry"
                                  : "Install"),
                        ),
                      if (viewModel.status ==
                              AutoUpdateStatus.checkingVersion ||
                          viewModel.status == AutoUpdateStatus.downloading ||
                          viewModel.status == AutoUpdateStatus.installing)
                        const Button(
                          child: Text("Installing…"),
                        ),
                      if (viewModel.status == AutoUpdateStatus.success)
                        Button(
                          onPressed: () {
                            if (Restart.supported) {
                              Restart.restart();
                            } else {
                              exit(0);
                            }
                          },
                          child: Text(Restart.supported ? "Restart" : "Exit"),
                        )
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
