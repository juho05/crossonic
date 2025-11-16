import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RefreshScrollView extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final ScrollController? controller;
  final List<Widget> slivers;

  const RefreshScrollView({
    super.key,
    required this.onRefresh,
    this.controller,
    required this.slivers,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final isCupertino =
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
    final scrollView = CustomScrollView(
      controller: controller,
      physics: isCupertino
          ? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isCupertino)
          CupertinoSliverRefreshControl(
            onRefresh: () {
              HapticFeedback.lightImpact();
              return onRefresh();
            },
          ),
        ...slivers,
      ],
    );
    if (!isCupertino) {
      return RefreshIndicator(onRefresh: onRefresh, child: scrollView);
    }
    return scrollView;
  }
}
