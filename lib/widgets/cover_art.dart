import 'package:cached_network_image/cached_network_image.dart';
import 'package:crossonic/repositories/subsonic/subsonic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum CoverType { song, album, artist, playlist }

class CoverResolution {
  final int size;

  const CoverResolution.extraLarge() : size = 1024;
  const CoverResolution.large() : size = 512;
  const CoverResolution.medium() : size = 256;
  const CoverResolution.small() : size = 128;
  const CoverResolution.tiny() : size = 64;
}

class CoverArt extends StatefulWidget {
  final String coverID;
  final CoverResolution resolution;
  final BorderRadiusGeometry borderRadius;
  final double? size;

  const CoverArt(
      {required this.coverID,
      required this.resolution,
      this.borderRadius = BorderRadius.zero,
      this.size,
      super.key});

  @override
  State<CoverArt> createState() => _CoverArtState();
}

class _CoverArtState extends State<CoverArt> {
  String? _url;

  String _loadedID = "";

  @override
  Widget build(BuildContext context) {
    if (_loadedID != widget.coverID) {
      _loadedID = widget.coverID;
      context
          .read<SubsonicRepository>()
          .getCoverArtURL(
              coverArtID: widget.coverID, size: widget.resolution.size)
          .then(
            (value) => setState(() {
              _url = value.toString();
            }),
          );
    }

    final Widget placeholder = Icon(
      Icons.album,
      size: widget.size,
      opticalSize: (widget.size ?? 0) > 0 ? widget.size : null,
    );

    Widget image;
    if (_url != null) {
      image = CachedNetworkImage(
        imageUrl: _url!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      );
    } else {
      image = placeholder;
    }
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: Clip.antiAlias,
        child: image,
      ),
    );
  }
}
