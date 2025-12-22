import 'package:crossonic/ui/common/shimmer.dart';
import 'package:flutter/material.dart';

class CrossonicDialog extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets contentPadding;

  const CrossonicDialog({
    super.key,
    this.maxWidth,
    this.contentPadding = const EdgeInsets.all(12),
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final shimmerGradient = Shimmer.createGradient(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(8),
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      child: Shimmer(
        linearGradient: shimmerGradient,
        child: Padding(padding: contentPadding, child: child),
      ),
    );
  }
}
