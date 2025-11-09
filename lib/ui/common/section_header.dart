import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String text;
  final List<Widget> trailing;

  const SectionHeader({
    super.key,
    this.trailing = const [],
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (trailing.isEmpty) {
      return Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...trailing,
      ],
    );
  }
}
