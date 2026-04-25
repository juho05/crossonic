/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:auto_route/annotations.dart';
import 'package:crossonic/ui/casting/casting_viewmodel.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/section_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class CastingPage extends StatefulWidget {
  const CastingPage({super.key});

  @override
  State<CastingPage> createState() => _CastingPageState();
}

class _CastingPageState extends State<CastingPage> {
  late final CastingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CastingViewModel(playbackManager: context.read());
    _viewModel.startDiscovery();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Casting")),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return CustomScrollView(
              slivers: [
                const SliverPadding(
                  padding: EdgeInsets.all(8.0),
                  sliver: SliverToBoxAdapter(
                    child: SectionHeader(text: "Current device"),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ClickableListItem(
                    title: _viewModel.currentDevice?.name ?? "No active device",
                    extraInfo: [
                      _viewModel.currentDevice?.type ?? "Local",
                      ...(_viewModel.currentDevice?.extraInfos ?? []),
                    ],
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        _viewModel.currentDevice?.icon ?? Icons.devices,
                      ),
                    ),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.all(8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 8,
                      children: [
                        SectionHeader(text: "Discovering"),
                        SizedBox.square(
                          dimension: 10,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverFixedExtentList.builder(
                  itemExtent: ClickableListItem.verticalExtent,
                  itemCount: _viewModel.discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = _viewModel.discoveredDevices[index];
                    return ClickableListItem(
                      key: ValueKey("$index-${device.hashCode}"),
                      title: device.name,
                      extraInfo: [device.type, ...device.extraInfos],
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Icon(device.icon),
                      ),
                      onTap: () {
                        // TODO
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
