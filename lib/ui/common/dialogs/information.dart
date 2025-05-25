import 'package:crossonic/ui/common/adaptive_dialog_action.dart';
import 'package:flutter/material.dart';

class InformationDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String btnTitle;
  const InformationDialog._({
    required this.title,
    required this.message,
    required this.btnTitle,
  });

  static Future<bool> show(BuildContext context, String title,
      {String? message, String? btnTitle}) async {
    final result = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) {
        return InformationDialog._(
          title: title,
          message: message,
          btnTitle: btnTitle ?? "Ok",
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(title),
      content: message != null ? Text(message!) : null,
      actions: [
        AdaptiveDialogAction(
          onPressed: () => Navigator.pop(context, true),
          child: Text(btnTitle),
        )
      ],
    );
  }
}
