/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/ui/common/shimmer.dart';
import 'package:flutter/material.dart';

class CrossonicDialog extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets contentPadding;

  const CrossonicDialog({
    super.key,
    this.maxWidth,
    this.contentPadding = const EdgeInsets.all(12),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerGradient = Shimmer.createGradient(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      child: Shimmer(
        linearGradient: shimmerGradient,
        child: Padding(padding: contentPadding, child: child),
      ),
    );
  }
}
