import 'package:crossonic/ui/common/text_scroll.dart';
import 'package:flutter/material.dart';

class ScrollingSongTitle extends StatelessWidget {
  final String title;
  final TextStyle? style;

  const ScrollingSongTitle({required this.title, this.style, super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: title,
      waitDuration: const Duration(milliseconds: 500),
      triggerMode: TooltipTriggerMode.manual,
      child: TextScroll(
        title,
        delayBefore: const Duration(seconds: 3),
        pauseBetween: const Duration(seconds: 3),
        fadedBorder: true,
        fadedBorderWidth: 0.025,
        fadeBorderSide: FadeBorderSide.right,
        intervalSpaces: 7,
        mode: TextScrollMode.endless,
        selectable: false,
        velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
        style: style,
      ),
    );
  }
}
