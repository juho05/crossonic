import 'package:crossonic/features/home/state/nav_bloc.dart';
import 'package:crossonic/features/home/view/bottom_navigation.dart';
import 'package:crossonic/features/home/view/home_page.dart';
import 'package:crossonic/features/playlists/playlists.dart';
import 'package:crossonic/features/search/view/search_page.dart';
import 'package:crossonic/features/settings/settings.dart';
import 'package:crossonic/page_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});
  static Route route() {
    return PageTransition(const MainPage());
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey(debugLabel: "navigator (Home)"),
    GlobalKey(debugLabel: "navigator (Search)"),
    GlobalKey(debugLabel: "navigator (Playlists)"),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavBloc(_navigatorKeys),
      child: BlocBuilder<NavBloc, NavState>(builder: (context, state) {
        final String tabName;
        switch (state.tabIndex) {
          case 0:
            tabName = "Home";
          case 1:
            tabName = "Search";
          case 2:
            tabName = "Playlists";
          default:
            tabName = "";
        }
        return PopScope(
          canPop: !state.canPop,
          onPopInvoked: (didPop) {
            context.read<NavBloc>().add(const NavPopped());
          },
          child: Scaffold(
            appBar: AppBar(
              leading: state.canPop
                  ? BackButton(
                      onPressed: () =>
                          context.read<NavBloc>().add(const NavPopped()),
                    )
                  : const Icon(Icons.music_note),
              title: Text('Crossonic | $tabName'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.push(context, SettingsPage.route());
                  },
                )
              ],
            ),
            body: Stack(
              children: [
                Offstage(
                  offstage: state.tabIndex != 0,
                  child: HeroControllerScope(
                    controller: MaterialApp.createMaterialHeroController(),
                    child: Navigator(
                      key: _navigatorKeys[0],
                      onGenerateRoute: (_) => HomePage.route(),
                    ),
                  ),
                ),
                Offstage(
                  offstage: state.tabIndex != 1,
                  child: HeroControllerScope(
                    controller: MaterialApp.createMaterialHeroController(),
                    child: Navigator(
                      key: _navigatorKeys[1],
                      onGenerateRoute: (_) => SearchPage.route(),
                    ),
                  ),
                ),
                Offstage(
                  offstage: state.tabIndex != 2,
                  child: HeroControllerScope(
                    controller: MaterialApp.createMaterialHeroController(),
                    child: Navigator(
                      key: _navigatorKeys[2],
                      onGenerateRoute: (_) => PlaylistsPage.route(),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigation(
              currentIndex: state.tabIndex,
              onIndexChanged: (newIndex) {
                context.read<NavBloc>().add(NavTabChanged(newIndex));
              },
            ),
          ),
        );
      }),
    );
  }
}
