/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

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
