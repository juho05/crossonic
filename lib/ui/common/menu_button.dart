import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final Iterable<ContextMenuOption> options;
  final Icon icon;
  final EdgeInsetsGeometry padding;

  const MenuButton({
    super.key,
    this.icon = const Icon(Icons.more_vert),
    required this.options,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ContextMenuOption>(
      icon: icon,
      padding: padding,
      onSelected: (option) {
        if (option.onSelected == null) return;
        option.onSelected!();
      },
      menuPadding: const EdgeInsets.all(0),
      itemBuilder: (context) => options
          .map(
            (o) => PopupMenuItem<ContextMenuOption>(
              value: o,
              height: 40,
              child: ListTile(
                minVerticalPadding: 0,
                minTileHeight: 40,
                mouseCursor: SystemMouseCursors.click,
                leading: o.icon != null ? Icon(o.icon) : null,
                title: Text(o.title),
              ),
            ),
          )
          .toList(),
    );
  }
}
