import 'package:crossonic/features/home/view/now_playing.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_sidemenu/easy_sidemenu.dart';

class MainPageDesktop extends StatefulWidget {
  final StatefulNavigationShell _navigationShell;

  const MainPageDesktop({
    Key? key,
    required StatefulNavigationShell navigationShell,
  })  : _navigationShell = navigationShell,
        super(key: key ?? const ValueKey("main_page_desktop_key"));

  @override
  State<MainPageDesktop> createState() => _MainPageDesktopState();
}

class _MainPageDesktopState extends State<MainPageDesktop> {
  @override
  void initState() {
    sideMenu.changePage(widget._navigationShell.currentIndex);
    sideMenu.addListener(onNavigate);
    super.initState();
  }

  void onNavigate(int index) {
    widget._navigationShell.goBranch(index,
        initialLocation: index == widget._navigationShell.currentIndex);
  }

  @override
  void dispose() {
    sideMenu.removeListener(onNavigate);
    super.dispose();
  }

  SideMenuController sideMenu = SideMenuController();

  @override
  Widget build(BuildContext context) {
    final hasMedia =
        context.select<NowPlayingCubit, bool>((value) => value.state.hasMedia);
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: SideMenu(
                      items: [
                        SideMenuItem(
                          title: "Home",
                          icon: const Icon(Icons.home),
                          onTap: (index, sideMenuController) =>
                              sideMenuController.changePage(index),
                        ),
                        SideMenuItem(
                          title: "Search",
                          icon: const Icon(Icons.search),
                          onTap: (index, sideMenuController) =>
                              sideMenuController.changePage(index),
                        ),
                        SideMenuItem(
                          title: "Playlists",
                          icon: const Icon(Icons.queue_music),
                          onTap: (index, sideMenuController) =>
                              sideMenuController.changePage(index),
                        ),
                      ],
                      controller: sideMenu,
                      style: SideMenuStyle(
                        selectedColor: theme.colorScheme.primaryContainer,
                        backgroundColor: theme.colorScheme.surface,
                        selectedTitleTextStyle: theme.textTheme.bodyLarge!
                            .copyWith(
                                color: theme.colorScheme.onPrimaryContainer),
                        unselectedTitleTextStyle: theme.textTheme.bodyLarge,
                        selectedIconColor: theme.colorScheme.onPrimaryContainer,
                        unselectedIconColor: theme.colorScheme.onSurface,
                        openSideMenuWidth: 180,
                        compactSideMenuWidth: 66,
                      ),
                      collapseWidth: 1300,
                    ),
                  ),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                  ),
                  Expanded(
                    child: widget._navigationShell,
                  ),
                ],
              ),
            ),
            if (hasMedia) const NowPlayingDesktop(),
          ],
        ),
      ),
    );
  }
}
