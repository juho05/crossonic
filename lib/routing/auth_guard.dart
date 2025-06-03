import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthRepository _authRepository;

  AuthGuard({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (resolver.routeName == DebugRoute.name ||
        resolver.routeName == LogsRoute.name) {
      resolver.next(true);
      return;
    }
    if (resolver.routeName == ConnectServerRoute.name) {
      resolver.next(!_authRepository.hasServer);
      return;
    }
    if (!_authRepository.hasServer) {
      resolver.next(false);
      router.replaceAll([const ConnectServerRoute()]);
      return;
    }

    if (resolver.routeName == LoginRoute.name) {
      resolver.next(!_authRepository.isAuthenticated);
      return;
    }

    if (!_authRepository.isAuthenticated) {
      resolver.next(false);
      router.replaceAll([const LoginRoute()]);
      return;
    }

    resolver.next(true);
  }
}
