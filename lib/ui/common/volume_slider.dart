/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'package:crossonic/ui/common/volume_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum VolumeSliderValuePosition { left, right, hidden }

class VolumeSlider extends StatefulWidget {
  final EdgeInsetsGeometry? padding;
  final VolumeSliderValuePosition valuePosition;
  final BoxConstraints? constraints;
  final bool showIcon;

  const VolumeSlider({
    super.key,
    this.padding,
    this.valuePosition = VolumeSliderValuePosition.right,
    this.showIcon = true,
    this.constraints,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  late final VolumeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = VolumeViewModel(playbackManager: context.read());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final slider = Slider(
          padding: widget.padding,
          value: _viewModel.volume,
          onChanged: (double value) {
            _viewModel.volume = value;
          },
          min: 0,
          max: 1,
          inactiveColor: Theme.of(context).colorScheme.primary.withAlpha(61),
        );

        final valueText = ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 25),
          child: Text((_viewModel.volume * 100).round().toString()),
        );

        final icon = const Icon(Icons.volume_up_outlined, size: 20);

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.valuePosition == VolumeSliderValuePosition.left)
              valueText
            else if (widget.showIcon)
              icon,

            if (widget.constraints != null)
              ConstrainedBox(constraints: widget.constraints!, child: slider)
            else
              Expanded(child: slider),

            if (widget.valuePosition == VolumeSliderValuePosition.right)
              valueText
            else if (widget.showIcon)
              icon,
          ],
        );
      },
    );
  }
}
