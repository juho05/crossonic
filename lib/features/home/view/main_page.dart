import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/features/home/view/main_page_desktop.dart';
import 'package:crossonic/features/home/view/main_page_mobile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Builder(builder: (context) {
      final layout = context.read<Layout>();
      if (layout.size == LayoutSize.desktop) {
        return MainPageDesktop(navigationShell: _navigationShell);
      } else {
        return MainPageMobile(navigationShell: _navigationShell);
      }
    });
  }
}
