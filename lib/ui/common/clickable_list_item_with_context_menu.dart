import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/context_menu_button.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';

class ClickableListItemWithContextMenu extends StatefulWidget {
  final String title;
  final bool titleBold;
  final Iterable<String> extraInfo;
  final Widget? leading;
  final String? trailingInfo;
  final void Function()? onTap;
  final bool isFavorite;

  final Iterable<ContextMenuOption> options;

  const ClickableListItemWithContextMenu({
    super.key,
    required this.title,
    required this.extraInfo,
    this.titleBold = false,
    this.leading,
    this.trailingInfo,
    this.onTap,
    this.options = const [],
    this.isFavorite = false,
  });

  @override
  State<ClickableListItemWithContextMenu> createState() =>
      _ClickableListItemWithContextMenuState();
}

class _ClickableListItemWithContextMenuState
    extends State<ClickableListItemWithContextMenu> {
  final _popupMenuButton = GlobalKey<State>();

  @override
  Widget build(BuildContext context) {
    return WithContextMenu(
      options: widget.options,
      popupMenuButtonKey: _popupMenuButton,
      child: ClickableListItem(
        title: widget.title,
        titleBold: widget.titleBold,
        extraInfo: widget.extraInfo,
        leading: widget.leading,
        isFavorite: widget.isFavorite,
        trailing: widget.options.isNotEmpty
            ? ContextMenuButton(
                popupMenuButtonKey: _popupMenuButton,
                options: widget.options,
              )
            : null,
        trailingInfo: widget.trailingInfo,
        onTap: widget.onTap,
      ),
    );
  }
}
