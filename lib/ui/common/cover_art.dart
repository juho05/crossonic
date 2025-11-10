import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/data/repositories/cover/cover_repository.dart';
import 'package:crossonic/data/repositories/subsonic/subsonic_repository.dart';
import 'package:crossonic/ui/common/shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CoverArt extends StatefulWidget {
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

  @override
  State<CoverArt> createState() => _CoverArtState();
}

class _CoverArtState extends State<CoverArt> {
  @override
  Widget build(BuildContext context) {
    placeholder(double size) {
      return Icon(
        widget.placeholderIcon,
        size: size * 0.8,
        opticalSize: size > 0 ? size * 0.8 : null,
      );
    }

    int resolution(BuildContext context, double size) {
      size *= MediaQuery.of(context).devicePixelRatio;
      if (size > 512) {
        return 1024;
      } else if (size > 256) {
        return 512;
      } else if (size > 128) {
        return 256;
      } else if (size > 64) {
        return 128;
      } else {
        return 64;
      }
    }

    Widget coverWidget(double size) {
      final image = widget.coverId != null
          ? (kIsWeb
                ? Image.network(
                    context
                        .read<SubsonicRepository>()
                        .getCoverUri(widget.coverId!, constantSalt: true)
                        .toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        placeholder(size),
                    frameBuilder:
                        (context, child, frame, wasSynchronouslyLoaded) {
                          if (frame == null) {
                            return placeholder(size);
                          }
                          return child;
                        },
                  )
                : CachedNetworkImage(
                    imageUrl: CoverRepository.getKey(
                      widget.coverId!,
                      resolution(context, size),
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => placeholder(size),
                    fadeInDuration: const Duration(milliseconds: 100),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => const ShimmerLoading(),
                    cacheManager: context.read<CoverRepository>(),
                  ))
          : placeholder(size);

      return SizedBox.square(
        dimension: size,
        child: widget.borderRadius == BorderRadius.zero
            ? image
            : ClipRRect(
                borderRadius: widget.borderRadius,
                clipBehavior: Clip.antiAlias,
                child: image,
              ),
      );
    }

    if (widget.size != null) {
      return coverWidget(widget.size!);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        return coverWidget(size);
      },
    );
  }
}
