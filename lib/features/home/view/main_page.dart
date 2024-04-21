import 'package:crossonic/features/home/view/bottom_navigation.dart';
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
    return Scaffold(
      body: _navigationShell,
      bottomNavigationBar: BottomNavigation(
        currentIndex: _navigationShell.currentIndex,
        onIndexChanged: (newIndex) {
          _navigationShell.goBranch(newIndex,
              initialLocation: newIndex == _navigationShell.currentIndex);
        },
      ),
    );
  }
}
