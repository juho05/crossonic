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
      path: "release/:id",
      page: AlbumRoute.page,
      title: (context, data) => "Release",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "artist/:id",
      page: ArtistRoute.page,
      title: (context, data) => "Artist",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "playlist/:id",
      page: PlaylistRoute.page,
      title: (context, data) => "Playlist",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "playlist/create",
      page: CreatePlaylistRoute.page,
      title: (context, data) => "Create Playlist",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "playlist/update/:id",
      page: UpdatePlaylistRoute.page,
      title: (context, data) => "Update Playlist",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "artists",
      page: ArtistsRoute.page,
      title: (context, data) => "Artists",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "releases",
      page: AlbumsRoute.page,
      title: (context, data) => "Releases",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "songs",
      page: SongsRoute.page,
      title: (context, data) => "Songs",
      restorationId: (match) => match.fullPath,
    ),
    AutoRoute(
      path: "genres",
      page: GenresRoute.page,
      title: (context, data) => "Genres",
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
              page: const EmptyShellRoute("HomeTab"),
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
              page: const EmptyShellRoute("BrowseTab"),
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
            AutoRoute(
              path: "playlists",
              page: const EmptyShellRoute("PlaylistTab"),
              title: (context, data) => "",
              children: [
                AutoRoute(
                  page: PlaylistsRoute.page,
                  path: "",
                  title: (context, data) => "Playlists",
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
          path: "/settings/homeLayout",
          page: HomeLayoutRoute.page,
          title: (context, data) => "Home Layout",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/appearance",
          page: AppearanceRoute.page,
          title: (context, data) => "Appearance",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/transcoding",
          page: TranscodingRoute.page,
          title: (context, data) => "Transcoding",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/replayGain",
          page: ReplayGainRoute.page,
          title: (context, data) => "Replay Gain",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/scan",
          page: ScanRoute.page,
          title: (context, data) => "Scan",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/listenBrainz",
          page: ListenBrainzRoute.page,
          title: (context, data) => "ListenBrainz",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/debug",
          page: DebugRoute.page,
          title: (context, data) => "Debug",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/debug/logs",
          page: LogsRoute.page,
          title: (context, data) => "Logs",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/settings/debug/logs/chooseSession",
          page: ChooseLogSessionRoute.page,
          title: (context, data) => "Choose Session",
          restorationId: (match) => match.fullPath,
        ),
        AutoRoute(
          path: "/lyrics",
          page: LyricsRoute.page,
          title: (context, data) => "Lyrics",
          restorationId: (match) => match.fullPath,
        )
      ];
}
