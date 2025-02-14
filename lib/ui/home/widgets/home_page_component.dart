import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class HomePageComponent extends StatelessWidget {
  final String text;
  final Widget child;
  final PageRouteInfo route;

  const HomePageComponent({
    super.key,
    required this.text,
    required this.child,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: () {
            context.router.push(route);
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            textStyle: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
          ),
          child: Row(
            children: [
              Text(text),
              Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurface),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
