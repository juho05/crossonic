import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget? child;

  const SubmitButton({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              fixedSize: Size.fromHeight(42),
            ),
            child: child,
          )
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              fixedSize: Size.fromHeight(42),
            ),
            child: child,
          );
  }
}
