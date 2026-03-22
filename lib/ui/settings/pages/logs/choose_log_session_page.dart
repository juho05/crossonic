/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/logger/log.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/settings/pages/logs/choose_log_session_page_viewmodel.dart';
import 'package:crossonic/utils/format.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ChooseLogSessionPage extends StatelessWidget {
  final DateTime? highlight;
  const ChooseLogSessionPage({super.key, this.highlight});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ChooseLogSessionPageViewModel(logRepository: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Choose Session")),
          body: SafeArea(
            child: Consumer<ChooseLogSessionPageViewModel>(
              builder: (context, viewModel, _) {
                return ListView.builder(
                  itemBuilder: (BuildContext context, int index) {
                    final s = viewModel
                        .sessions[viewModel.sessions.length - 1 - index];
                    final title =
                        formatDateTime(s) +
                        (s == Log.sessionStartTime ? " (Current)" : "");
                    return ClickableListItem(
                      title: title,
                      titleBold: s == highlight,
                      onTap: () {
                        context.router.maybePop<DateTime>(s);
                      },
                      trailing: s == highlight
                          ? const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.check),
                            )
                          : null,
                    );
                  },
                  itemCount: viewModel.sessions.length,
                  itemExtent: ClickableListItem.verticalExtent,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
