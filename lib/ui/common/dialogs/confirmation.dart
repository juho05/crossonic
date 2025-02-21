import 'package:flutter/cupertino.dart';
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
      [String title = "Are you sure?", String? message]) async {
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

  Widget _adaptiveAction(
      {required BuildContext context,
      required VoidCallback onPressed,
      required Widget child}) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
      default:
        return TextButton(onPressed: onPressed, child: child);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        _adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, false),
          child: Text(noBtnTitle),
        ),
        _adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    );
  }
}
