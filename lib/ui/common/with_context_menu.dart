import 'dart:ui';

import 'package:flutter/material.dart';

class ContextMenuOption {
  final IconData? icon;
  final String title;
  final void Function()? onSelected;

  ContextMenuOption({
    this.icon,
    required this.title,
    required this.onSelected,
  });
}

class WithContextMenu extends StatelessWidget {
  final Widget child;
  final GlobalKey<State> popupMenuButtonKey;
  final Iterable<ContextMenuOption> options;

  const WithContextMenu({
    super.key,
    required this.child,
    required this.popupMenuButtonKey,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    Offset? mouseClickPosition;
    return GestureDetector(
      onSecondaryTapDown: (details) {
        if (details.kind != PointerDeviceKind.mouse) return;
        mouseClickPosition = details.globalPosition;
      },
      onSecondaryTap: () async {
        if (mouseClickPosition == null || options.isEmpty) return;
        final overlay = Overlay.of(context).context.findRenderObject();
        if (overlay == null) return;
        final popupButtonObject =
            popupMenuButtonKey.currentContext?.findRenderObject();
        if (popupButtonObject == null) return;
        final mousePos = mouseClickPosition;
        final mediaQuery = MediaQuery.of(context);
        final result = showMenu(
          context: context,
          position: RelativeRect.fromRect(
              Rect.fromLTWH(
                mousePos!.dx -
                    (mediaQuery.size.width - overlay.paintBounds.width),
                mousePos.dy - 56, // app bar: 56px
                popupButtonObject.paintBounds.width,
                popupButtonObject.paintBounds.height,
              ),
              Rect.fromLTWH(
                  0, 0, overlay.paintBounds.width, overlay.paintBounds.height)),
          items: options
              .map(
                (o) => PopupMenuItem<ContextMenuOption>(
                  value: o,
                  child: ListTile(
                    leading: o.icon != null ? Icon(o.icon) : null,
                    title: Text(o.title),
                  ),
                ),
              )
              .toList(),
        );
        mouseClickPosition = null;
        final option = await result;
        if (option != null && option.onSelected != null) {
          option.onSelected!();
        }
      },
      child: child,
    );
  }
}
