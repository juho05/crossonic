/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RefreshScrollView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final List<Widget> slivers;

  const RefreshScrollView({
    super.key,
    required this.onRefresh,
    this.controller,
    required this.slivers,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final scrollView = CustomScrollView(
      controller: controller,
      physics: isCupertino
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isCupertino)
          CupertinoSliverRefreshControl(
            onRefresh: () {
              HapticFeedback.lightImpact();
              return onRefresh();
            },
          ),
        ...slivers,
      ],
    );
    if (!isCupertino) {
      return RefreshIndicator(onRefresh: onRefresh, child: scrollView);
    }
    return scrollView;
  }
}
