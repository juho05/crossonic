/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/system_integration.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AppImagePage extends StatelessWidget {
  const AppImagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImageSettingsPage(
      config: systemIntegrationConfig,
      appImageRepository: context.read(),
      showMessage: Toast.show,
    );
  }
}
