import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class HomePageComponent extends StatelessWidget {
  final String text;
  final PageRouteInfo? route;
  final Widget child;

  const HomePageComponent({
    super.key,
    required this.text,
    required this.route,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: route != null
              ? () {
                  context.router.push(route!);
                }
              : null,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            textStyle: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
          ),
          child: Row(
            children: [
              Text(
                text,
                style: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
              ),
              if (route != null)
                Icon(Icons.arrow_forward_ios,
                    color: theme.colorScheme.onSurface),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
