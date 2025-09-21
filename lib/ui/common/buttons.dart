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
  final Color? color;

  const Button({
    super.key,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.style,
    this.darkTonal = false,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        buttonTheme: theme.buttonTheme.copyWith(
          buttonColor: color,
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: color != null ? BorderSide(color: color!) : null,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: color,
          ),
        ),
      ),
      child: Builder(
        builder: (context) {
          if (outlined) {
            return OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: icon != null ? Icon(icon, color: color) : null,
              label: child,
            );
          }
          return theme.brightness == Brightness.dark && darkTonal
              ? FilledButton.tonalIcon(
                  onPressed: onPressed,
                  style: style,
                  icon: icon != null
                      ? Icon(icon, color: color != null ? Colors.white : null)
                      : null,
                  label: child,
                )
              : FilledButton.icon(
                  onPressed: onPressed,
                  style: style,
                  icon: icon != null
                      ? Icon(icon, color: color != null ? Colors.white : null)
                      : null,
                  label: child,
                );
        },
      ),
    );
  }
}
