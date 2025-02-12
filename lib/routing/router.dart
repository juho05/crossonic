import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/auth_guard.dart';
import 'package:crossonic/routing/router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  final AuthRepository _authRepository;
  AppRouter({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  @override
  List<AutoRouteGuard> get guards => [
        AuthGuard(authRepository: _authRepository),
      ];

  final List<AutoRoute> _childRoutes = [
    AutoRoute(
      path: "artist",
      page: ArtistRoute.page,
      restorationId: (match) => match.fullPath,
    ),
  ];

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          path: "/",
          page: MainRoute.page,
          children: [
            AutoRoute(
              path: "home",
              page: EmptyShellRoute("HomeTab"),
              children: [
                AutoRoute(page: HomeRoute.page, path: ""),
                ..._childRoutes,
              ],
              restorationId: (match) => match.fullPath,
            ),
            AutoRoute(
              path: "browse",
              page: EmptyShellRoute("BrowseTab"),
              children: [
                AutoRoute(page: BrowseRoute.page, path: ""),
                ..._childRoutes,
              ],
              restorationId: (match) => match.fullPath,
            ),
          ],
        ),
        AutoRoute(
          path: "/auth/connect",
          page: ConnectServerRoute.page,
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/auth/login",
          page: LoginRoute.page,
          restorationId: (match) => match.fullPath,
        ),
      ];
}
