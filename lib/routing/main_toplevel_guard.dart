/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';

class MainTopLevelGuard extends AutoRouteGuard {
  const MainTopLevelGuard();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (resolver.routeName != MainRoute.name) {
      resolver.next();
      return;
    }
    if (router.stack.length > 1) {
      router.popUntilRouteWithName(resolver.routeName);
      final route = resolver.route.flattened
          .map((r) => PageRouteInfo.fromMatch(r))
          .last;
      router.push(route);
      resolver.next(false);
      return;
    }
    resolver.next();
  }
}
