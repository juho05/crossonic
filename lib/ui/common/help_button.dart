import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:flutter/material.dart';

class HelpButton extends StatelessWidget {
  final String dialogTitle;
  final String? dialogContentText;
  final Widget? dialogContent;

  const HelpButton({
    super.key,
    required this.dialogTitle,
    this.dialogContentText,
    this.dialogContent,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        showAdaptiveDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => AlertDialog.adaptive(
            title: Text(dialogTitle, textAlign: TextAlign.center, maxLines: 4),
            content: dialogContent ?? Text(dialogContentText ?? ""),
            actions: [
              AdaptiveDialogAction(
                child: const Text("Ok"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.info_outline),
    );
  }
}
