import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/auth/auth_repository.dart';
import 'package:crossonic/routing/router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  final AuthRepository _authRepository;

  AuthGuard({required AuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (resolver.routeName == ConnectServerRoute.name) {
      resolver.next(true);
      return;
    }
    if (!_authRepository.hasServer) {
      resolver.redirect(
        ConnectServerRoute(onServerSelected: () => resolver.next(true)),
      );
      return;
    }

    if (!_authRepository.isAuthenticated &&
        resolver.routeName != LoginRoute.name) {
      resolver.redirect(
        LoginRoute(onSignedIn: () => resolver.next(true)),
      );
      return;
    }

    resolver.next(true);
  }
}
