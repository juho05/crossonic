import 'dart:io';

import 'package:crossonic/main.dart';
import 'package:crossonic/ui/common/dialogs/information.dart';
import 'package:crossonic/ui/install_gstreamer/install_gstreamer_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:dynamic_system_colors/dynamic_system_colors.dart';
import 'package:flutter/material.dart';
import 'package:linkfy_text/linkfy_text.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InstallGStreamer extends StatelessWidget {
  final Widget child;

  const InstallGStreamer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (BuildContext context) => InstallGStreamerViewModel(),
      child: Consumer<InstallGStreamerViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == GStreamerStatus.installed) {
            return child;
          }

          return DynamicColorBuilder(
              builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            return MaterialApp(
              title: "Crossonic",
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightDynamic ?? defaultLightColorScheme,
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkDynamic ?? defaultDarkColorScheme,
              ),
              home: Scaffold(
                body: SafeArea(
                  child: Builder(
                    builder: (context) {
                      if (viewModel.status == GStreamerStatus.unknown) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                      final textTheme = Theme.of(context).textTheme;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "Install GStreamer",
                              style: textTheme.displayMedium,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 12,
                              children: [
                                Text(
                                  "Crossonic requires GStreamer to play back music,\nbut it is not currently installed on your computer.",
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyLarge,
                                ),
                                if (viewModel.supportsAutoInstall)
                                  Text(
                                    "Please click below to automatically install GStreamer.",
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyLarge,
                                  ),
                                if (!viewModel.supportsAutoInstall)
                                  LinkifyText(
                                    "Please install GStreamer Runtime and restart Crossonic:\nhttps://gstreamer.freedesktop.org/download",
                                    onTap: (link) {
                                      if (link.value == null) return;
                                      launchUrlString(link.value!);
                                    },
                                    textAlign: TextAlign.center,
                                    textStyle: textTheme.bodyLarge,
                                    linkStyle: textTheme.bodyLarge!.copyWith(
                                      decoration: TextDecoration.underline,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                if (viewModel.error != null)
                                  LinkifyText(
                                    viewModel.error!,
                                    onTap: (link) {
                                      if (link.value == null) return;
                                      launchUrlString(link.value!);
                                    },
                                    textAlign: TextAlign.center,
                                    textStyle: textTheme.bodyLarge!.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error),
                                    linkStyle: textTheme.bodyLarge!.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                              ],
                            ),
                            if (viewModel.supportsAutoInstall)
                              FilledButton.icon(
                                onPressed: !viewModel.downloading &&
                                        !viewModel.installing
                                    ? () async {
                                        final result =
                                            await viewModel.install();
                                        if (result is Ok &&
                                            viewModel.status !=
                                                GStreamerStatus.installed) {
                                          if (!context.mounted) return;
                                          if (await InformationDialog.show(
                                            context,
                                            "GStreamer installed",
                                            message:
                                                "Please restart Crossonic.",
                                            btnTitle: "Exit",
                                          )) {
                                            exit(0);
                                          }
                                        }
                                      }
                                    : null,
                                icon: viewModel.downloading
                                    ? CircularProgressIndicator(
                                        value: viewModel.downloadProgress)
                                    : viewModel.installing
                                        ? const CircularProgressIndicator
                                            .adaptive()
                                        : const Icon(Icons.install_desktop),
                                label: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  child: viewModel.downloading
                                      ? const Text("Downloading…")
                                      : viewModel.installing
                                          ? const Text("Installing…")
                                          : const Text("Install GStreamer"),
                                ),
                              ),
                            if (!viewModel.supportsAutoInstall)
                              FilledButton.icon(
                                onPressed: () => exit(0),
                                icon: const Icon(Icons.logout),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 14),
                                  child: Text("Exit"),
                                ),
                              )
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          });
        },
      ),
    );
  }
}
