import 'package:flutter/material.dart';

/*
class _FadePageTransition extends StatelessWidget {
  _FadePageTransition({
    required Animation<double> routeAnimation,
    required this.child,
  }) : _opacityAnimation = routeAnimation.drive(_easeInTween);

  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);

  final Animation<double> _opacityAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: child,
    );
  }
}
*/

class PageTransition extends PageRouteBuilder {
  PageTransition(Widget page)
      : super(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionDuration: const Duration(milliseconds: 100));
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    //return _FadePageTransition(routeAnimation: animation, child: child);
    return const CupertinoPageTransitionsBuilder()
        .buildTransitions(this, context, animation, secondaryAnimation, child);
  }
}
