import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class ContextMenuButton extends StatelessWidget {
  final Key? popupMenuButtonKey;
  final Iterable<ContextMenuOption> options;
  final Icon? icon;

  const ContextMenuButton({
    super.key,
    this.popupMenuButtonKey,
    this.icon = const Icon(Icons.more_vert),
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ContextMenuOption>(
      key: popupMenuButtonKey,
      icon: icon,
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
