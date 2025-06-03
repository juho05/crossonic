import 'package:flutter/material.dart';

class Toast {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      dismissDirection: DismissDirection.down,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(milliseconds: 2500),
      padding: const EdgeInsets.all(8),
      showCloseIcon: true,
    ));
  }
}
