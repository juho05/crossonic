import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/data/services/restart/restart.dart';
import 'package:crossonic/integrate_appimage_viewmodel.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class IntegrateAppImage extends StatelessWidget {
  final Widget child;

  const IntegrateAppImage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppImageRepository.isAppImage) {
      return child;
    }
    return Consumer<IntegrateAppImageViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.askToIntegrate) {
          viewModel.shownDialog();
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            final answer = await ConfirmationDialog.showYesNoCancel(
              context,
              title: "Integrate AppImage?",
              message:
                  "Would you like to properly integrate Crossonic into your desktop environment?",
              cancelBtn: "Later",
            );
            if (answer == null) return;
            if (!answer) {
              await viewModel.disable();
              return;
            }
            final result = await viewModel.integrate();
            if (result is Err) {
              if (!context.mounted) return;
              toastResult(context, result);
              return;
            }
            Restart.restart();
          });
        }
        return child;
      },
    );
  }
}
