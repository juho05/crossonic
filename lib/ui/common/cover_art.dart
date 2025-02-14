import 'dart:math';

import 'package:crossonic/ui/common/cover_art_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

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
    viewModel = CoverArtViewModel(subsonicRepository: context.read());
    if (widget.coverId != null) viewModel.load(widget.coverId!);
  }

  @override
  Widget build(BuildContext context) {
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
          if (viewModel.uri == null) {
            return placeholder;
          }
          return SizedBox.square(
            dimension: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                placeholder,
                ClipRRect(
                  borderRadius: widget.borderRadius,
                  clipBehavior: Clip.antiAlias,
                  child: FadeInImage.memoryNetwork(
                      image: viewModel.uri!.toString(),
                      placeholder: kTransparentImage,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (context, error, stackTrace) {
                        print(viewModel.uri!.toString());
                        print(error);
                        print(stackTrace);
                        return SizedBox.shrink();
                      }),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
