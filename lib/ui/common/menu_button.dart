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
import 'package:material_ui/material_ui.dart';

// Looks and behaves like a Material 3 IconButton opening a PopupMenuButton
// menu, but is built from a bare InkResponse. An IconButton carries its own
// Material with an animation ticker, style resolution and a Tooltip, which
// adds up when one sits in every list row that is created while scrolling.
// Tooltips are only built on desktop, mobile never shows them.
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
    final theme = Theme.of(context);
    final popupMenuTheme = PopupMenuTheme.of(context);
    final iconTheme = IconTheme.of(context);
    final size = iconSize ?? popupMenuTheme.iconSize ?? iconTheme.size ?? 24;
    final overlay = theme.colorScheme.onSurfaceVariant;
    Widget button = InkResponse(
      onTap: () => _showMenu(context),
      radius: size / 2 + 8,
      highlightShape: BoxShape.circle,
      splashFactory: theme.splashFactory,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return overlay.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return overlay.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return overlay.withValues(alpha: 0.1);
        }
        return null;
      }),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: kMinInteractiveDimension,
          minHeight: kMinInteractiveDimension,
        ),
        child: Padding(
          padding: padding,
          child: IconTheme.merge(
            data: IconThemeData(
              size: size,
              color: popupMenuTheme.iconColor ?? iconTheme.color,
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
    button = Semantics(button: true, child: button);
    if (_compact) {
      button = Tooltip(
        message: tooltip ?? MaterialLocalizations.of(context).showMenuTooltip,
        child: button,
      );
    }
    return button;
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
