import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        HomeRoute(),
        BrowseRoute(),
      ],
      homeIndex: 0,
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) => Row(
            children: [
              if (orientation == Orientation.landscape)
                SafeArea(
                  child: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: tabsRouter.activeIndex,
                        onDestinationSelected: (index) =>
                            tabsRouter.setActiveIndex(index),
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          NavigationRailDestination(
                            icon: Icon(Icons.home_outlined),
                            selectedIcon: Icon(Icons.home),
                            label: Text("Home"),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.library_music_outlined),
                            selectedIcon: Icon(Icons.library_music),
                            label: Text("Browse"),
                          ),
                        ],
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                    ],
                  ),
                ),
              Expanded(
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(tabsRouter.topPage!.routeData.title(context)),
                    leading: tabsRouter.activeRouterCanPop()
                        ? AutoLeadingButton()
                        : null,
                  ),
                  body: SafeArea(
                    child: child,
                  ),
                  bottomNavigationBar: orientation == Orientation.portrait
                      ? BottomNavigationBar(
                          currentIndex: tabsRouter.activeIndex,
                          onTap: (index) => tabsRouter.setActiveIndex(index),
                          items: [
                            BottomNavigationBarItem(
                              icon: Icon(tabsRouter.activeIndex == 0
                                  ? Icons.home
                                  : Icons.home_outlined),
                              label: "Home",
                            ),
                            BottomNavigationBarItem(
                              icon: Icon(tabsRouter.activeIndex == 1
                                  ? Icons.library_music
                                  : Icons.library_music_outlined),
                              label: "Browse",
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
