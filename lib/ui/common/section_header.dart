/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final List<Widget> trailing;

  const SectionHeader({
    super.key,
    this.trailing = const [],
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (trailing.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...trailing,
      ],
    );
  }
}
