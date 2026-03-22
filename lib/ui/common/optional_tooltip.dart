/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class OptionalTooltip extends StatelessWidget {
  final String? message;
  final Widget child;
  final bool triggerOnLongPress;
  final bool enableDelay;

  const OptionalTooltip({
    super.key,
    this.message,
    this.triggerOnLongPress = true,
    this.enableDelay = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return child;
    return Tooltip(
      triggerMode: triggerOnLongPress
          ? TooltipTriggerMode.longPress
          : TooltipTriggerMode.manual,
      waitDuration: const Duration(milliseconds: 500),
      message: message,
      child: child,
    );
  }
}
