/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class OptionalTooltip extends StatelessWidget {
  final String? message;
  final Widget child;
  final bool enableDelay;

  const OptionalTooltip({
    super.key,
    this.message,
    this.enableDelay = true,
    required this.child,
  });

  static final bool enabled = kIsWeb || !(Platform.isAndroid || Platform.isIOS);

  static Widget wrap({
    String? message,
    bool enableDelay = true,
    required Widget child,
  }) {
    if (!enabled || message == null || message.isEmpty) return child;
    return OptionalTooltip(
      message: message,
      enableDelay: enableDelay,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return child;
    if (!enabled) return child;

    return Tooltip(
      triggerMode: TooltipTriggerMode.manual,
      waitDuration: const Duration(milliseconds: 500),
      message: message,
      child: child,
    );
  }
}
