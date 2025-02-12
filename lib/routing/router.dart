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

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          path: "/",
          page: MainRoute.page,
        ),
        AutoRoute(
          path: "/auth/connect",
          page: ConnectServerRoute.page,
        ),
        AutoRoute(
          path: "/auth/login",
          page: LoginRoute.page,
        ),
      ];
}
