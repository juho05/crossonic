import 'package:crossonic/ui/common/shimmer.dart';
import 'package:flutter/material.dart';

class CrossonicDialog extends StatelessWidget {
  final Widget child;

  const CrossonicDialog({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final shimmerGradient = Shimmer.createGradient(context);
    return Dialog(
      child: Shimmer(linearGradient: shimmerGradient, child: child),
    );
  }
}
