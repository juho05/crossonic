import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class ContextMenuButton extends StatelessWidget {
  final Key? popupMenuButtonKey;
  final Iterable<ContextMenuOption> options;
  final Icon? icon;
  final EdgeInsetsGeometry padding;

  const ContextMenuButton({
    super.key,
    this.popupMenuButtonKey,
    this.icon = const Icon(Icons.more_vert),
    required this.options,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ContextMenuOption>(
      key: popupMenuButtonKey,
      icon: icon,
      padding: padding,
      onSelected: (option) {
        if (option.onSelected == null) return;
        option.onSelected!();
      },
      itemBuilder: (context) => options
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
  }
}
