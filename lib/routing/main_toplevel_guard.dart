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
