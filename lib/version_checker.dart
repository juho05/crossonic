import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/version_checker_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

enum VersionDialogChoice { ignore, remind, view, install }

class VersionChecker extends StatelessWidget {
  final Widget child;

  const VersionChecker({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<VersionCheckerViewModel>(
      builder: (context, viewModel, _) {
        bool isApple = defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS;
        if (viewModel.newVersionAvailable && !viewModel.isOpen) {
          SchedulerBinding.instance.addPostFrameCallback((_) {
            final actions = [
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.ignore),
                child: const Text("Ignore"),
              ),
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.remind),
                child: const Text("Remind later"),
              ),
              AdaptiveDialogAction(
                onPressed: () =>
                    Navigator.pop(context, VersionDialogChoice.view),
                child: const Text("View"),
              ),
              if (AutoUpdateRepository.autoUpdatesSupported)
                AdaptiveDialogAction(
                  onPressed: () =>
                      Navigator.pop(context, VersionDialogChoice.install),
                  child: const Text("Install"),
                )
            ];
            viewModel.isOpen = true;
            showAdaptiveDialog<VersionDialogChoice>(
              context: context,
              builder: (context) {
                return AlertDialog.adaptive(
                  title: const Text("New version available"),
                  content: Text(
                      "Current: v${viewModel.current}\nLatest: v${viewModel.latest}"),
                  actions: isApple ? actions.reversed.toList() : actions,
                );
              },
            ).then((choice) async {
              if (!context.mounted) return;
              switch (choice) {
                case VersionDialogChoice.ignore:
                  await viewModel.ignoreVersion();
                  if (context.mounted) {
                    Toast.show(context,
                        "You won't be reminded about this version again");
                  }
                  break;
                case VersionDialogChoice.view:
                  launchUrl(
                      Uri.https("github.com", "/juho05/crossonic/releases"));
                case null:
                case VersionDialogChoice.remind:
                  // default behavior
                  break;
                case VersionDialogChoice.install:
                  context.router.push(const InstallUpdateRoute());
              }
              await viewModel.displayedVersionDialog();
            });
          });
        }
        return child;
      },
    );
  }
}
