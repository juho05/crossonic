/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/ui/common/optional_tooltip.dart';
import 'package:crossonic/ui/common/text_scroll.dart';
import 'package:flutter/material.dart';

class ScrollingSongTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final TextAlign? textAlign;

  const ScrollingSongTitle({
    required this.title,
    this.style,
    this.textAlign,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return OptionalTooltip(
      message: title,
      triggerOnLongPress: false,
      child: TextScroll(
        title,
        textAlign: textAlign,
        delayBefore: const Duration(seconds: 3),
        pauseBetween: const Duration(seconds: 3),
        fadedBorder: true,
        fadedBorderWidth: 0.025,
        fadeBorderSide: FadeBorderSide.right,
        intervalSpaces: 7,
        mode: TextScrollMode.endless,
        selectable: false,
        velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
        style: style,
      ),
    );
  }
}
