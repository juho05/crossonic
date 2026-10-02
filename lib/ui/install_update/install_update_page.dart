/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/utils/exit.dart';
import 'package:flutter_system_integration/flutter_system_integration.dart'
    as fsi;
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

@RoutePage()
class InstallUpdatePage extends StatelessWidget {
  const InstallUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return fsi.InstallUpdatePage(
      autoUpdateRepository: fsi.AutoUpdateRepository.autoUpdatesSupported
          ? context.read()
          : null,
      onExit: exitApp,
    );
  }
}
