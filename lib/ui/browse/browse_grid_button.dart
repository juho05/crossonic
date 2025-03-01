import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class BrowseGridButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final PageRouteInfo route;

  const BrowseGridButton({
    super.key,
    required this.icon,
    required this.text,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: InkWell(
              onTap: () => context.router.push(route),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Icon(icon, size: constraints.maxHeight * 0.5),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: constraints.maxHeight * 0.1,
                    ),
                    textAlign: TextAlign.center,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
