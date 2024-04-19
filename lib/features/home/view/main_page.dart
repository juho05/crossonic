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
  static Route route(BuildContext context, Object? arguments) {
    return PageTransition(const MainPage());
  }

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with RestorationMixin {
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey(debugLabel: "navigator (Home)"),
    GlobalKey(debugLabel: "navigator (Search)"),
    GlobalKey(debugLabel: "navigator (Playlists)"),
  ];

  final _currentTab = RestorableInt(0);

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
        if (_currentTab.value != state.tabIndex) {
          context.read<NavBloc>().add(NavTabChanged(_currentTab.value));
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
                    Navigator.restorablePush(context, SettingsPage.route);
                  },
                )
              ],
            ),
            body: Stack(
              children: [
                Offstage(
                  offstage: state.tabIndex != 0,
                  child: Navigator(
                    key: _navigatorKeys[0],
                    onGenerateRoute: (_) => HomePage.route(context, null),
                  ),
                ),
                Offstage(
                  offstage: state.tabIndex != 1,
                  child: Navigator(
                    key: _navigatorKeys[1],
                    onGenerateRoute: (_) => SearchPage.route(context, null),
                  ),
                ),
                Offstage(
                  offstage: state.tabIndex != 2,
                  child: Navigator(
                    key: _navigatorKeys[2],
                    onGenerateRoute: (_) => PlaylistsPage.route(context, null),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigation(
              currentIndex: state.tabIndex,
              onIndexChanged: (newIndex) {
                _currentTab.value = newIndex;
                context.read<NavBloc>().add(NavTabChanged(newIndex));
              },
            ),
          ),
        );
      }),
    );
  }

  @override
  String? get restorationId => "main_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_currentTab, "main_page_current_tab");
  }
}
