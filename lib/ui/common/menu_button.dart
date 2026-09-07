/*
 * Copyright 2024-2026 Julian Hofmann (+ Crossonic contributors).
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:io';

import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  static final bool _compact =
      kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  final Iterable<ContextMenuOption> options;
  final Icon icon;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final double? iconSize;

  const MenuButton({
    super.key,
    this.icon = const Icon(Icons.more_vert),
    this.iconSize,
    required this.options,
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final popupMenuTheme = PopupMenuTheme.of(context);
    final iconTheme = IconTheme.of(context);
    return IconButton(
      icon: icon,
      iconSize: iconSize ?? popupMenuTheme.iconSize ?? iconTheme.size,
      color: popupMenuTheme.iconColor ?? iconTheme.color,
      padding: padding,
      tooltip: _compact
          ? tooltip ?? MaterialLocalizations.of(context).showMenuTooltip
          : null,
      onPressed: () => _showMenu(context),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    if (options.isEmpty) return;
    final button = context.findRenderObject()! as RenderBox;
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    final option = await showMenu<ContextMenuOption>(
      context: context,
      position: position,
      menuPadding: const EdgeInsets.all(0),
      items: options
          .map(
            (o) => PopupMenuItem<ContextMenuOption>(
              value: o,
              height: _compact ? 40 : kMinInteractiveDimension,
              child: ListTile(
                minVerticalPadding: _compact ? 0 : null,
                minTileHeight: _compact ? 40 : null,
                mouseCursor: SystemMouseCursors.click,
                leading: o.icon != null ? Icon(o.icon) : null,
                title: Text(o.title),
              ),
            ),
          )
          .toList(),
    );
    option?.onSelected?.call();
  }
}
