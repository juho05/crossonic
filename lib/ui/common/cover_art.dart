/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';
import 'dart:math';

import 'package:crossonic/data/repositories/cover/cover_image_provider.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/common/loading_box.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoverArt extends StatelessWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;
  final double? size;

  const CoverArt({
    super.key,
    this.coverId,
    this.size,
    required this.placeholderIcon,
    this.borderRadius = BorderRadius.zero,
  });

  static int _resolution(double pixelSize) {
    if (pixelSize > 512) {
      return 1024;
    } else if (pixelSize > 256) {
      return 512;
    } else if (pixelSize > 128) {
      return 256;
    } else if (pixelSize > 64) {
      return 128;
    } else {
      return 64;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (size != null) {
      return _build(context, size!);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return _build(
          context,
          min(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }

  Widget _build(BuildContext context, double size) {
    final placeholder = _PlaceholderIcon(icon: placeholderIcon, size: size);
    final Widget content;
    if (coverId == null) {
      content = placeholder;
    } else {
      final pixelSize = size * MediaQuery.devicePixelRatioOf(context);
      final resolution = _resolution(pixelSize);
      final ImageProvider image;
      if (kIsWeb) {
        image = NetworkImage(
          context
              .read<SubsonicRepository>()
              .getCoverUri(coverId!, constantSalt: true, size: resolution)
              .toString(),
        );
      } else {
        image = CoverImageProvider(
          context.read<CoverRepository>(),
          coverId: coverId!,
          resolution: resolution,
          targetSize: Platform.isAndroid || Platform.isIOS
              ? pixelSize.ceil()
              : null,
        );
      }
      content = _CoverImage(image: image, errorPlaceholder: placeholder);
    }
    return SizedBox.square(
      dimension: size,
      child: borderRadius == BorderRadius.zero
          ? content
          : ClipRRect(
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: content,
            ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _PlaceholderIcon({required this.icon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size * 0.8,
      opticalSize: size > 0 ? size * 0.8 : null,
    );
  }
}

class _CoverImage extends StatefulWidget {
  final ImageProvider image;
  final Widget errorPlaceholder;

  const _CoverImage({required this.image, required this.errorPlaceholder});

  @override
  State<_CoverImage> createState() => _CoverImageState();
}

class _CoverImageState extends State<_CoverImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  bool _fadeStarted = false;

  @override
  void didUpdateWidget(covariant _CoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _fadeStarted = false;
      _fade.value = 0;
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame != null && !_fadeStarted) {
      _fadeStarted = true;
      if (wasSynchronouslyLoaded) {
        _fade.value = 1;
      } else {
        _fade.forward();
      }
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    return LoadingBox(
      child: Image(
        image: widget.image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        excludeFromSemantics: true,
        opacity: _fade,
        frameBuilder: _frameBuilder,
        errorBuilder: (context, error, stackTrace) => widget.errorPlaceholder,
      ),
    );
  }
}
