import 'package:crossonic/features/home/view/bottom_navigation.dart';
import 'package:crossonic/features/home/view/now_playing.dart';
import 'package:crossonic/features/home/view/state/now_playing_cubit.dart';
import 'package:crossonic/services/audio_handler/audio_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MainPageMobile extends StatefulWidget {
  final StatefulNavigationShell _navigationShell;

  const MainPageMobile({
    Key? key,
    required StatefulNavigationShell navigationShell,
  })  : _navigationShell = navigationShell,
        super(key: key ?? const ValueKey("main_page_mobile_key"));

  @override
  State<MainPageMobile> createState() => _MainPageMobileState();
}

class _MainPageMobileState extends State<MainPageMobile> {
  final _slidingUpPanelController = PanelController();

  var _collapsedVisible = true;
  var _expandedVisible = false;

  @override
  Widget build(BuildContext context) {
    final hasMedia =
        context.select<NowPlayingCubit, bool>((value) => value.state.hasMedia);
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      body: LayoutBuilder(builder: (context, constraints) {
        return SlidingUpPanel(
          minHeight: hasMedia ? 53 : 0,
          maxHeight: hasMedia ? constraints.maxHeight : 0,
          borderRadius: BorderRadius.zero,
          controller: _slidingUpPanelController,
          collapsed: Visibility(
            visible: _collapsedVisible && hasMedia,
            child:
                NowPlayingCollapsed(panelController: _slidingUpPanelController),
          ),
          panelBuilder: (_) => Visibility(
            visible: _expandedVisible,
            child: NowPlayingExpanded(
              panelController: _slidingUpPanelController,
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: (hasMedia ? 113 : 60) + bottomPadding),
              child: BlocListener<NowPlayingCubit, NowPlayingState>(
                listenWhen: (previous, current) =>
                    previous.playbackState.status !=
                    current.playbackState.status,
                listener: (context, state) {
                  if (state.playbackState.status ==
                          CrossonicPlaybackStatus.stopped &&
                      _slidingUpPanelController.isPanelOpen) {
                    _slidingUpPanelController.close();
                  }
                },
                child: widget._navigationShell,
              ),
            ),
          ),
          onPanelSlide: (position) {
            if (!_collapsedVisible || !_expandedVisible) {
              setState(() {
                _collapsedVisible = true;
                _expandedVisible = true;
              });
            }
          },
          onPanelClosed: () {
            if (!_collapsedVisible || _expandedVisible) {
              setState(() {
                _collapsedVisible = true;
                _expandedVisible = false;
              });
            }
          },
          onPanelOpened: () {
            if (_collapsedVisible || !_expandedVisible) {
              setState(() {
                _collapsedVisible = false;
                _expandedVisible = true;
              });
            }
          },
        );
      }),
      bottomNavigationBar: SafeArea(
        child: SizedBox(
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
      ),
    );
  }
}
