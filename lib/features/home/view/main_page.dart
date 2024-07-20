import 'package:crossonic/features/home/view/main_page_desktop.dart';
import 'package:crossonic/features/home/view/main_page_mobile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  final StatefulNavigationShell _navigationShell;
  const MainPage({
    Key? key,
    required StatefulNavigationShell navigationShell,
  })  : _navigationShell = navigationShell,
        super(key: key ?? const ValueKey("main_page_key"));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 1000) {
        return MainPageDesktop(navigationShell: _navigationShell);
      } else {
        return MainPageMobile(navigationShell: _navigationShell);
      }
    });
  }
}
