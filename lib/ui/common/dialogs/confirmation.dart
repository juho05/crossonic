import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String noBtnTitle;
  const ConfirmationDialog._({
    required this.title,
    required this.message,
    required this.noBtnTitle,
  });

  static Future<bool> showCancel(BuildContext context,
      [String title = "Are you sure?", String? message]) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog._(
          title: title,
          message: message,
          noBtnTitle: "Cancel",
        );
      },
    );
    return result ?? false;
  }

  static Future<bool?> showYesNo(BuildContext context,
      {String title = "Are you sure?", String? message}) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog._(
          title: title,
          message: message,
          noBtnTitle: "No",
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        AdaptiveDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: Text(noBtnTitle),
        ),
        AdaptiveDialogAction(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        )
      ],
    );
  }
}
