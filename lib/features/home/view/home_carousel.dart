import 'package:flutter/material.dart';

class HomeCarousel extends StatelessWidget {
  final String title;
  final Widget content;
  final void Function()? onMore;
  const HomeCarousel({
    super.key,
    required this.title,
    required this.content,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          onPressed: onMore,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            textStyle: theme.textTheme.headlineSmall!.copyWith(fontSize: 20),
          ),
          child: Row(
            children: [
              Text(title),
              const Icon(
                Icons.arrow_forward_ios,
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: content,
        ),
      ],
    );
  }
}
