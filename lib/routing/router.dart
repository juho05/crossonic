import 'package:crossonic/features/auth/auth.dart';
import 'package:crossonic/features/home/home.dart';
import 'package:crossonic/features/home/view/home_page.dart';
import 'package:crossonic/features/login/login.dart';
import 'package:crossonic/features/playlists/playlists.dart';
import 'package:crossonic/features/search/view/search_page.dart';
import 'package:crossonic/features/settings/settings.dart';
import 'package:crossonic/features/splash/splash.dart';
import 'package:crossonic/repositories/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _searchNavigatorKey = GlobalKey<NavigatorState>();
final _playlistsNavigatorKey = GlobalKey<NavigatorState>();

final _topLevelRoutes = [
  _newRoute("/", const SplashPage()),
  _newRoute("/login", const LoginPage()),
  _newRoute("/settings", const SettingsPage()),
];

String _tabRoutePath(String prefix, String path) =>
    prefix == path ? path : '$prefix$path';

List<RouteBase> _tabRoutes(String prefix) => [
      _newRoute(_tabRoutePath(prefix, "/home"), const HomePage()),
      _newRoute(_tabRoutePath(prefix, "/search"), const SearchPage()),
      _newRoute(_tabRoutePath(prefix, "/playlists"), const PlaylistsPage()),
    ];

final goRouter = GoRouter(
  initialLocation: "/",
  restorationScopeId: "go_router",
  navigatorKey: _rootNavigatorKey,
  routes: [
    ..._topLevelRoutes,
    StatefulShellRoute.indexedStack(
      restorationScopeId: "main_page_route",
      pageBuilder: (context, state, navigationShell) => NoTransitionPage(
        child: MainPage(navigationShell: navigationShell),
        restorationId: "main_page",
      ),
      branches: [
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          restorationScopeId: "home_branch",
          initialLocation: "/home",
          routes: _tabRoutes("/home"),
        ),
        StatefulShellBranch(
          navigatorKey: _searchNavigatorKey,
          restorationScopeId: "search_branch",
          initialLocation: "/search",
          routes: _tabRoutes("/search"),
        ),
        StatefulShellBranch(
          navigatorKey: _playlistsNavigatorKey,
          restorationScopeId: "playlists_branch",
          initialLocation: "/playlists",
          routes: _tabRoutes("/playlists"),
        ),
      ],
    )
  ],
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    if (state.fullPath == "/") {
      if (authState.status == AuthStatus.authenticated) {
        return "/home";
      }
      if (authState.status == AuthStatus.unauthenticated) {
        return "/login";
      }
    } else if (state.fullPath == "/login") {
      if (authState.status == AuthStatus.authenticated) {
        return "/home";
      }
    } else {
      if (authState.status == AuthStatus.unauthenticated) {
        return "/login";
      }
    }
    return null;
  },
);

GoRoute _newRoute(String path, Widget page) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => NoTransitionPage(
      child: page,
      restorationId: path,
    ),
  );
}
