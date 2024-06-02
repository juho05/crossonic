import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  const ConfirmationDialog._({
    required this.title,
  });

  static Future<bool> show(BuildContext context,
      [String title = "Are you sure?"]) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog._(
          title: title,
        );
      },
    );
    return result ?? false;
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
      actions: [
        _adaptiveAction(
          context: context,
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
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
