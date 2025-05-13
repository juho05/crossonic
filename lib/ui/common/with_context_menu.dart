import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class WithContextMenu extends StatefulWidget {
  final Widget child;
  final Iterable<ContextMenuOption> options;

  const WithContextMenu({
    super.key,
    required this.child,
    required this.options,
  });

  @override
  State<WithContextMenu> createState() => _WithContextMenuState();
}

class _WithContextMenuState extends State<WithContextMenu> {
  final MenuController _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onSecondaryTapDown: _handleSecondaryTapDown,
      behavior: HitTestBehavior.opaque,
      child: MenuAnchor(
        controller: _controller,
        consumeOutsideTap: true,
        anchorTapClosesMenu: true,
        menuChildren: widget.options
            .map((o) => MenuItemButton(
                  onPressed: o.onSelected,
                  leadingIcon: o.icon != null ? Icon(o.icon) : null,
                  child: Text(o.title),
                ))
            .toList(),
        child: widget.child,
      ),
    );
  }

  void _handleSecondaryTapDown(TapDownDetails details) {
    _controller.open(position: details.localPosition);
  }

  void _handleTapDown(TapDownDetails details) {
    if (_controller.isOpen) {
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      if (HardwareKeyboard.instance.isControlPressed) {
        _controller.open(position: details.localPosition);
      }
    }
  }
}
