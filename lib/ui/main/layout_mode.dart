import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LayoutModeManager extends ChangeNotifier {
  bool _isDesktop = false;

  bool get desktop => _isDesktop;
  bool get mobile => !_isDesktop;

  void update(bool isDesktop) {
    if (isDesktop == _isDesktop) return;
    _isDesktop = isDesktop;
    notifyListeners();
  }
}

class LayoutModeBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool isDesktop) builder;

  const LayoutModeBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<LayoutModeManager>(
      builder: (context, manager, _) {
        return builder(context, manager.desktop);
      },
    );
  }
}
