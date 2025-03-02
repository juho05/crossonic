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
      path: "album/:id",
      page: AlbumRoute.page,
      title: (context, data) => "Album",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "artist/:id",
      page: ArtistRoute.page,
      title: (context, data) => "Artist",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "artists",
      page: ArtistsRoute.page,
      title: (context, data) => "Artists",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "albums",
      page: AlbumsRoute.page,
      title: (context, data) => "Albums",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "songs",
      page: SongsRoute.page,
      title: (context, data) => "Songs",
      restorationId: (match) => match.fullPath,
    )
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
              title: (context, data) => "",
              children: [
                AutoRoute(
                  page: HomeRoute.page,
                  path: "",
                  title: (context, data) => "Home",
                ),
                ..._childRoutes,
              ],
              restorationId: (match) => match.fullPath,
            ),
            AutoRoute(
              path: "browse",
              page: EmptyShellRoute("BrowseTab"),
              title: (context, data) => "",
              children: [
                AutoRoute(
                  page: BrowseRoute.page,
                  path: "",
                  title: (context, data) => "Browse",
                ),
                ..._childRoutes,
              ],
              restorationId: (match) => match.fullPath,
            ),
          ],
        ),
        AutoRoute(
          path: "/auth/connect",
          page: ConnectServerRoute.page,
          title: (context, data) => "Connect Server",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/auth/login",
          page: LoginRoute.page,
          title: (context, data) => "Login",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/queue",
          page: QueueRoute.page,
          title: (context, data) => "Queue",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings",
          page: SettingsRoute.page,
          title: (context, data) => "Settings",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/scan",
          page: ScanRoute.page,
          title: (context, data) => "Scan",
          restorationId: (match) => match.fullPath,
        )
      ];
}
