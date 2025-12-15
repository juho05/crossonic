import 'package:flutter/material.dart';

class OptionalTooltip extends StatelessWidget {
  final String? message;
  final Widget child;
  final bool triggerOnLongPress;
  final bool enableDelay;

  const OptionalTooltip({
    super.key,
    this.message,
    this.triggerOnLongPress = true,
    this.enableDelay = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return child;
    return Tooltip(
      triggerMode: triggerOnLongPress
          ? TooltipTriggerMode.longPress
          : TooltipTriggerMode.manual,
      waitDuration: const Duration(milliseconds: 500),
      message: message,
      child: child,
    );
  }
}
