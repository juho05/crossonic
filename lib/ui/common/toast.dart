/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class Toast {
  static void show(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        dismissDirection: DismissDirection.down,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2500),
        padding: const EdgeInsets.all(8),
        showCloseIcon: true,
      ),
    );
  }
}
