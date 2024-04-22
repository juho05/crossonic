import 'package:crossonic/features/home/view/bottom_navigation.dart';
import 'package:crossonic/features/home/view/now_playing.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MainPage extends StatefulWidget {
  final StatefulNavigationShell _navigationShell;

  const MainPage({
    Key? key,
    required StatefulNavigationShell navigationShell,
  })  : _navigationShell = navigationShell,
        super(key: key ?? const ValueKey("main_page_key"));

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _slidingUpPanelController = PanelController();

  var _collapsedVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final hasMedia = context
              .select<NowPlayingCubit, bool>((value) => value.state.hasMedia);
          return SlidingUpPanel(
            minHeight: hasMedia ? 50 : 0,
            maxHeight: hasMedia ? constraints.maxHeight : 0,
            borderRadius: BorderRadius.zero,
            controller: _slidingUpPanelController,
            collapsed: Visibility(
              visible: _collapsedVisible,
              child: NowPlayingCollapsed(
                  panelController: _slidingUpPanelController),
            ),
            panelBuilder: (_) => NowPlaying(
              panelController: _slidingUpPanelController,
            ),
            body: Padding(
              padding: EdgeInsets.only(bottom: hasMedia ? 110 : 60),
              child: widget._navigationShell,
            ),
            onPanelSlide: (position) {
              setState(() {
                _collapsedVisible = true;
              });
            },
            onPanelClosed: () {
              setState(() {
                _collapsedVisible = true;
              });
            },
            onPanelOpened: () {
              setState(() {
                _collapsedVisible = false;
              });
            },
          );
        }),
      ),
      bottomNavigationBar: SizedBox(
        height: 60,
        child: BottomNavigation(
          currentIndex: widget._navigationShell.currentIndex,
          onIndexChanged: (newIndex) {
            if (_slidingUpPanelController.isAttached) {
              _slidingUpPanelController.close();
            }
            widget._navigationShell.goBranch(newIndex,
                initialLocation:
                    newIndex == widget._navigationShell.currentIndex);
          },
        ),
      ),
    );
  }
}
