/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:math';

import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CoverArtDecorated extends StatelessWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;
  final bool uploading;

  final double? size;

  final bool isFavorite;
  final DownloadStatus downloadStatus;

  final Iterable<ContextMenuOption> menuOptions;

  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;

  const CoverArtDecorated({
    super.key,
    this.coverId,
    required this.placeholderIcon,
    required this.borderRadius,
    required this.isFavorite,
    this.size,
    this.uploading = false,
    this.downloadStatus = DownloadStatus.none,
    this.menuOptions = const [],
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  bool get _showMenu => menuOptions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final Widget child = size != null
        ? _buildContent(context, size!)
        : LayoutBuilder(
            builder: (context, constraints) => _buildContent(
              context,
              min(constraints.maxWidth, constraints.maxHeight),
            ),
          );
    if (_showMenu) {
      return WithContextMenu(options: menuOptions, child: child);
    }
    return child;
  }

  Widget _buildContent(BuildContext context, double size) {
    if (uploading) {
      return Align(
        alignment: Alignment.center,
        child: SizedBox.square(
          dimension: size,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator.adaptive(),
          ),
        ),
      );
    }

    final largeLayout = size >= 256;
    final cover = CoverArt(
      size: size,
      placeholderIcon: placeholderIcon,
      borderRadius: borderRadius,
      coverId: coverId,
    );

    final stackChildren = [
      cover,
      if (topLeft != null || isFavorite)
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.all(largeLayout ? 8 : 3),
            child:
                topLeft ??
                DecoratedIcon(
                  decoration: const IconDecoration(
                    border: IconBorder(color: Colors.black, width: 2),
                  ),
                  icon: Icon(
                    Icons.favorite,
                    size: largeLayout ? 26 : 20,
                    color: const Color.fromARGB(255, 248, 248, 248),
                  ),
                ),
          ),
        ),
      if (topRight != null || downloadStatus != DownloadStatus.none)
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: EdgeInsets.all(largeLayout ? 8 : 3),
            child:
                topRight ??
                DecoratedIcon(
                  decoration: const IconDecoration(
                    border: IconBorder(color: Colors.black, width: 1),
                  ),
                  icon: Icon(
                    downloadStatus == DownloadStatus.downloading
                        ? Icons.downloading_outlined
                        : Icons.download_for_offline_outlined,
                    size: largeLayout ? 26 : 20,
                    color: const Color.fromARGB(255, 248, 248, 248),
                  ),
                ),
          ),
        ),
      if (bottomLeft != null)
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.all(largeLayout ? 8 : 3),
            child: bottomLeft,
          ),
        ),
      if (bottomRight != null || _showMenu)
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: EdgeInsets.all(largeLayout ? 8 : 3),
            child: bottomRight ?? OnCoverMenuButton(menuOptions: menuOptions),
          ),
        ),
    ];

    if (stackChildren.length == 1) {
      return Align(alignment: Alignment.center, child: cover);
    }

    return Align(
      alignment: Alignment.center,
      child: SizedBox.square(
        dimension: size,
        child: Provider<OnCoverIconButtonSize>.value(
          value: largeLayout
              ? OnCoverIconButtonSize.large
              : OnCoverIconButtonSize.normal,
          child: Stack(
            fit: StackFit.loose,
            alignment: Alignment.center,
            children: stackChildren,
          ),
        ),
      ),
    );
  }
}

enum OnCoverIconButtonSize { normal, large }

class OnCoverIconButton extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;

  const OnCoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return _OnCoverButton(
      button: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.all(0),
        icon: Icon(
          Icons.more_vert,
          size: size == OnCoverIconButtonSize.large ? 26 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class OnCoverMenuButton extends StatelessWidget {
  final Iterable<ContextMenuOption> menuOptions;
  final IconData icon;
  final String? tooltip;

  const OnCoverMenuButton({
    super.key,
    required this.menuOptions,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return _OnCoverButton(
      button: MenuButton(
        options: menuOptions,
        padding: const EdgeInsets.all(0),
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: size == OnCoverIconButtonSize.large ? 26 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _OnCoverButton extends StatelessWidget {
  final Widget button;

  const _OnCoverButton({required this.button});

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return SizedBox.square(
      dimension: size == OnCoverIconButtonSize.large ? 40 : 30,
      child: Material(
        color: Colors.black.withAlpha(90),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: button,
      ),
    );
  }
}
