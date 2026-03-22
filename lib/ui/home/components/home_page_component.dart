/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class HomePageComponent extends StatelessWidget {
  final String text;
  final PageRouteInfo? route;
  final Widget sliver;

  const HomePageComponent({
    super.key,
    required this.text,
    required this.route,
    required this.sliver,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: TextButton(
            onPressed: route != null
                ? () {
                    context.router.push(route!);
                  }
                : null,
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface,
              textStyle: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
            ),
            child: Row(
              children: [
                Text(
                  text,
                  style: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
                ),
                if (route != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: theme.colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
        sliver,
      ],
    );
  }
}
