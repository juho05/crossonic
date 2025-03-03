import 'dart:math';

import 'package:crossonic/ui/common/cover_art_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoverArt extends StatefulWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;

  const CoverArt({
    super.key,
    this.coverId,
    required this.placeholderIcon,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  State<CoverArt> createState() => _CoverArtState();
}

class _CoverArtState extends State<CoverArt> {
  late final CoverArtViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = CoverArtViewModel(coverRepository: context.read());
    if (widget.coverId != null) viewModel.updateId(widget.coverId!);
  }

  @override
  Widget build(BuildContext context) {
    viewModel.updateId(widget.coverId);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, child) {
        return LayoutBuilder(builder: (context, constraints) {
          final size = min(constraints.maxWidth, constraints.maxHeight);
          final placeholder = Icon(
            widget.placeholderIcon,
            size: size * 0.8,
            opticalSize: size > 0 ? size * 0.8 : null,
          );
          if (viewModel.image == null) {
            if (viewModel.status == FetchStatus.initial) {
              return Container();
            }
            return placeholder;
          }
          return AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              clipBehavior: Clip.antiAlias,
              child: Image.file(
                viewModel.image!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
            ),
          );
        });
      },
    );
  }
}
