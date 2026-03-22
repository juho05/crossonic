/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveDialogAction extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;

  const AdaptiveDialogAction({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(onPressed: onPressed, child: child);
      default:
        return TextButton(onPressed: onPressed, child: child);
    }
  }
}
