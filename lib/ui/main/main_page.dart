import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/audio/audio_handler.dart';
import 'package:crossonic/data/repositories/playlist/playlist_repository.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/integrate_appimage.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/home/home_viewmodel.dart';
import 'package:crossonic/ui/main/layout_mode.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_collapsed.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_desktop.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_expanded.dart';
import 'package:crossonic/ui/main/now_playing/now_playing_viewmodel.dart';
import 'package:crossonic/version_checker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final NowPlayingViewModel _nowPlayingViewModel;
  late final LayoutModeManager _layoutModeManager;

  final _slidingUpPanelController = PanelController();

  var _collapsedVisible = true;
  var _expandedVisible = false;

  @override
  void initState() {
    super.initState();
    _nowPlayingViewModel = NowPlayingViewModel(
      audioHandler: context.read(),
      favoritesRepository: context.read(),
    );
    _layoutModeManager = LayoutModeManager();
  }

  @override
  Widget build(BuildContext context) {
    return VersionChecker(
      child: IntegrateAppImage(
        child: ChangeNotifierProvider(
            create: (context) => HomeViewModel(
                  settings: context.read<SettingsRepository>().homeLayout,
                  subsonicRepository: context.read(),
                ),
            builder: (context, _) {
              return AutoTabsRouter(
                routes: const [
                  HomeRoute(),
                  BrowseRoute(),
                  PlaylistsRoute(),
                ],
                homeIndex: 0,
                builder: (context, child) {
                  final tabsRouter = AutoTabsRouter.of(context);

                  Future<void> switchTab(int index) async {
                    try {
                      _slidingUpPanelController.close();
                    } catch (_) {}

                    if (index == 3) {
                      context.router.push(const SettingsRoute());
                      return;
                    }

                    if (index == tabsRouter.activeIndex) {
                      final routeName = switch (index) {
                        0 => "HomeRoute",
                        1 => "BrowseRoute",
                        2 => "PlaylistsRoute",
                        _ => ""
                      };
                      final router = tabsRouter.childControllers
                          .firstWhere((c) => c.stack.first.name == routeName);
                      while (router.canPop()) {
                        await router.maybePop();
                      }
                      return;
                    }
                    switch (index) {
                      case 0:
                        context.read<HomeViewModel>().refresh(false);
                      case 2:
                        context.read<PlaylistRepository>().refresh();
                    }
                    tabsRouter.setActiveIndex(index);
                  }

                  return ChangeNotifierProvider.value(
                    value: _layoutModeManager,
                    builder: (context, _) {
                      return OrientationBuilder(
                        builder:
                            (BuildContext context, Orientation orientation) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _layoutModeManager
                                .update(orientation == Orientation.landscape);
                          });
                          return ListenableBuilder(
                            listenable: _nowPlayingViewModel,
                            builder: (context, _) {
                              final Widget body;
                              if (orientation == Orientation.portrait) {
                                final stopped =
                                    _nowPlayingViewModel.playbackStatus ==
                                        PlaybackStatus.stopped;
                                if (stopped) {
                                  try {
                                    _slidingUpPanelController.close();
                                  } catch (_) {}
                                }
                                final bottomPadding =
                                    MediaQuery.of(context).viewPadding.bottom;
                                body = LayoutBuilder(
                                  builder: (context, constraints) =>
                                      SlidingUpPanel(
                                    minHeight: stopped ? 0 : 53,
                                    maxHeight:
                                        stopped ? 0 : constraints.maxHeight,
                                    borderRadius: BorderRadius.zero,
                                    controller: _slidingUpPanelController,
                                    collapsed: Visibility(
                                      visible: _collapsedVisible && !stopped,
                                      child: NowPlayingCollapsed(
                                        panelController:
                                            _slidingUpPanelController,
                                        viewModel: _nowPlayingViewModel,
                                      ),
                                    ),
                                    panelBuilder: (_) => Visibility(
                                      visible: _expandedVisible,
                                      child: NowPlayingExpanded(
                                        panelController:
                                            _slidingUpPanelController,
                                        viewModel: _nowPlayingViewModel,
                                      ),
                                    ),
                                    onPanelSlide: (position) {
                                      if (!_collapsedVisible ||
                                          !_expandedVisible) {
                                        setState(() {
                                          _collapsedVisible = true;
                                          _expandedVisible = true;
                                        });
                                      }
                                    },
                                    onPanelClosed: () {
                                      if (!_collapsedVisible ||
                                          _expandedVisible) {
                                        setState(() {
                                          _collapsedVisible = true;
                                          _expandedVisible = false;
                                        });
                                      }
                                    },
                                    onPanelOpened: () {
                                      if (_collapsedVisible ||
                                          !_expandedVisible) {
                                        setState(() {
                                          _collapsedVisible = false;
                                          _expandedVisible = true;
                                        });
                                      }
                                    },
                                    body: Scaffold(
                                      appBar: AppBar(
                                        title: PageTitle(router: tabsRouter),
                                        leading: tabsRouter.activeRouterCanPop()
                                            ? const AutoLeadingButton()
                                            : null,
                                        forceMaterialTransparency: true,
                                        actions: [
                                          IconButton(
                                            icon: const Icon(Icons.settings),
                                            onPressed: () {
                                              context.router
                                                  .push(const SettingsRoute());
                                            },
                                          ),
                                        ],
                                      ),
                                      body: Padding(
                                        padding: EdgeInsets.only(
                                            bottom: (stopped ? 58 : 111) +
                                                bottomPadding),
                                        child: SafeArea(
                                          child: child,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                try {
                                  _collapsedVisible = true;
                                  _expandedVisible = false;
                                  _slidingUpPanelController.close();
                                } catch (_) {}
                                body = Scaffold(
                                  appBar: AppBar(
                                    title: PageTitle(router: tabsRouter),
                                    forceMaterialTransparency: true,
                                    leading: tabsRouter.activeRouterCanPop()
                                        ? const AutoLeadingButton()
                                        : null,
                                    actions: [
                                      if (!tabsRouter.activeRouterCanPop() &&
                                          tabsRouter.activeIndex == 0)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: IconButton(
                                            onPressed: () {
                                              context
                                                  .read<HomeViewModel>()
                                                  .refresh(true);
                                            },
                                            icon: const Icon(Icons.refresh),
                                          ),
                                        )
                                    ],
                                  ),
                                  body: Column(
                                    children: [
                                      Expanded(
                                          child: SafeArea(
                                              bottom: false, child: child)),
                                      ListenableBuilder(
                                        listenable: _nowPlayingViewModel,
                                        builder: (context, _) {
                                          if (_nowPlayingViewModel
                                                  .playbackStatus ==
                                              PlaybackStatus.stopped) {
                                            return const SizedBox.shrink();
                                          }
                                          return NowPlayingDesktop(
                                            viewModel: _nowPlayingViewModel,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Row(
                                children: [
                                  if (orientation == Orientation.landscape)
                                    Row(
                                      children: [
                                        NavigationRail(
                                          selectedIndex: tabsRouter.activeIndex,
                                          onDestinationSelected: switchTab,
                                          labelType:
                                              NavigationRailLabelType.all,
                                          destinations: [
                                            const NavigationRailDestination(
                                              icon: Icon(Icons.home_outlined),
                                              selectedIcon: Icon(Icons.home),
                                              label: Text("Home"),
                                            ),
                                            const NavigationRailDestination(
                                              icon: Icon(
                                                  Icons.library_music_outlined),
                                              selectedIcon:
                                                  Icon(Icons.library_music),
                                              label: Text("Browse"),
                                            ),
                                            const NavigationRailDestination(
                                              icon: Icon(
                                                  Icons.queue_music_outlined),
                                              selectedIcon:
                                                  Icon(Icons.queue_music),
                                              label: Text("Playlists"),
                                            ),
                                            const NavigationRailDestination(
                                              icon: Icon(Icons.settings),
                                              selectedIcon:
                                                  Icon(Icons.settings),
                                              label: Text("Settings"),
                                            ),
                                          ],
                                        ),
                                        const VerticalDivider(
                                            thickness: 1, width: 1),
                                      ],
                                    ),
                                  Expanded(
                                    child: Scaffold(
                                      body: body,
                                      bottomNavigationBar: orientation ==
                                              Orientation.portrait
                                          ? BottomNavigationBar(
                                              useLegacyColorScheme: false,
                                              currentIndex:
                                                  tabsRouter.activeIndex,
                                              onTap: switchTab,
                                              items: [
                                                BottomNavigationBarItem(
                                                  icon: Icon(tabsRouter
                                                              .activeIndex ==
                                                          0
                                                      ? Icons.home
                                                      : Icons.home_outlined),
                                                  label: "Home",
                                                ),
                                                BottomNavigationBarItem(
                                                  icon: Icon(tabsRouter
                                                              .activeIndex ==
                                                          1
                                                      ? Icons.library_music
                                                      : Icons
                                                          .library_music_outlined),
                                                  label: "Browse",
                                                ),
                                                BottomNavigationBarItem(
                                                  icon: Icon(tabsRouter
                                                              .activeIndex ==
                                                          2
                                                      ? Icons.queue_music
                                                      : Icons
                                                          .queue_music_outlined),
                                                  label: "Playlists",
                                                ),
                                              ],
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            }),
      ),
    );
  }

  @override
  void dispose() {
    _nowPlayingViewModel.dispose();
    _layoutModeManager.dispose();
    super.dispose();
  }
}

class PageTitle extends StatefulWidget {
  final TabsRouter router;
  const PageTitle({super.key, required this.router});

  @override
  State<PageTitle> createState() => _PageTitleState();
}

class _PageTitleState extends State<PageTitle> {
  int _retryCounter = 0;
  @override
  Widget build(BuildContext context) {
    final title = widget.router.topPage?.routeData.title(context) ?? "";
    if (title.isEmpty) {
      if (_retryCounter < 10) {
        Future.delayed(const Duration(milliseconds: 10), () {
          setState(() {
            _retryCounter++;
          });
        });
      }
    } else {
      _retryCounter = 0;
    }
    return Text(title);
  }
}
