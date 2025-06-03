import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;

  const SubmitButton({super.key, this.onPressed, required this.child});

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        fixedSize: const Size.fromHeight(42),
      ),
      darkTonal: true,
      child: child,
    );
  }
}

class Button extends StatelessWidget {
  final void Function()? onPressed;
  final IconData? icon;
  final bool outlined;
  final ButtonStyle? style;
  final bool darkTonal;
  final Widget child;

  const Button({
    super.key,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.style,
    this.darkTonal = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: icon != null ? Icon(icon) : null,
        label: child,
      );
    }
    return Theme.of(context).brightness == Brightness.dark && darkTonal
        ? FilledButton.tonalIcon(
            onPressed: onPressed,
            style: style,
            icon: icon != null ? Icon(icon) : null,
            label: child,
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon != null ? Icon(icon) : null,
            label: child,
          );
  }
}
