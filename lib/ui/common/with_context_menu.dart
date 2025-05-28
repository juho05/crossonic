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
  @override
  Widget build(BuildContext context) {
    return ContextMenu(
      contextMenuBuilder: (context, offset) {
        return AdaptiveTextSelectionToolbar(
          anchors: TextSelectionToolbarAnchors(primaryAnchor: offset),
          children: widget.options
              .map((o) => Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: MenuItemButton(
                      leadingIcon: o.icon != null ? Icon(o.icon) : null,
                      onPressed: () {
                        if (o.onSelected != null) {
                          o.onSelected!();
                        }
                        CustomContextMenuController.removeAny();
                      },
                      child: Text(o.title),
                    ),
                  ))
              .toList(),
        );
      },
      child: widget.child,
    );
  }
}

typedef ContextMenuBuilder = Widget Function(
    BuildContext context, Offset offset);

class ContextMenu extends StatefulWidget {
  /// Builds the context menu.
  final ContextMenuBuilder contextMenuBuilder;

  /// The child widget that will be listened to for gestures.
  final Widget child;

  const ContextMenu(
      {super.key, required this.child, required this.contextMenuBuilder});

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  final CustomContextMenuController _contextMenuController =
      CustomContextMenuController();

  void _onSecondaryTapUp(TapUpDetails details) {
    _show(details.globalPosition);
  }

  void _onTap() {
    ContextMenuController.removeAny();
  }

  void _show(Offset position) {
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (BuildContext context) {
        return widget.contextMenuBuilder(context, position);
      },
    );
  }

  void _hide() {
    _contextMenuController.remove();
  }

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: _onSecondaryTapUp,
      onTap: _onTap,
      child: widget.child,
    );
  }
}

class CustomContextMenuController {
  /// Creates a context menu that can be shown with [show].
  CustomContextMenuController({this.onRemove});

  /// Called when this menu is removed.
  final VoidCallback? onRemove;

  /// The currently shown instance, if any.
  static CustomContextMenuController? _shownInstance;

  // The OverlayEntry is static because only one context menu can be displayed
  // at one time.
  static OverlayEntry? _menuOverlayEntry;

  static final FocusNode _focusNode = FocusNode();

  /// Shows the given context menu.
  ///
  /// Since there can only be one shown context menu at a time, calling this
  /// will also remove any other context menu that is visible.
  void show({
    required BuildContext context,
    required WidgetBuilder contextMenuBuilder,
    Widget? debugRequiredFor,
  }) {
    removeAny();
    final OverlayState overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );
    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.maybeOf(context)?.context,
    );

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () {
            removeAny();
          },
          onSecondaryTap: () {
            removeAny();
          },
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              if (event.logicalKey == LogicalKeyboardKey.escape) {
                removeAny();
                return KeyEventResult.handled;
              } else {
                return KeyEventResult.ignored;
              }
            },
            child: Container(
              color: Colors.transparent,
              child: capturedThemes.wrap(contextMenuBuilder(context)),
            ),
          ),
        );
      },
    );
    overlayState.insert(_menuOverlayEntry!);
    _shownInstance = this;
    _focusNode.requestFocus();
  }

  /// Remove the currently shown context menu from the UI.
  ///
  /// Does nothing if no context menu is currently shown.
  ///
  /// If a menu is removed, and that menu provided an [onRemove] callback when
  /// it was created, then that callback will be called.
  ///
  /// See also:
  ///
  ///  * [remove], which removes only the current instance.
  static void removeAny() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry?.dispose();
    _menuOverlayEntry = null;
    if (_shownInstance != null) {
      _shownInstance!.onRemove?.call();
      _shownInstance = null;
    }
  }

  /// True if and only if this menu is currently being shown.
  bool get isShown => _shownInstance == this;

  /// Cause the underlying [OverlayEntry] to rebuild during the next pipeline
  /// flush.
  ///
  /// It's necessary to call this function if the output of `contextMenuBuilder`
  /// has changed.
  ///
  /// Errors if the context menu is not currently shown.
  ///
  /// See also:
  ///
  ///  * [OverlayEntry.markNeedsBuild]
  void markNeedsBuild() {
    assert(isShown);
    _menuOverlayEntry?.markNeedsBuild();
  }

  /// Remove this menu from the UI.
  ///
  /// Does nothing if this instance is not currently shown. In other words, if
  /// another context menu is currently shown, that menu will not be removed.
  ///
  /// This method should only be called once. The instance cannot be shown again
  /// after removing. Create a new instance.
  ///
  /// If an [onRemove] method was given to this instance, it will be called.
  ///
  /// See also:
  ///
  ///  * [removeAny], which removes any shown instance of the context menu.
  void remove() {
    if (!isShown) {
      return;
    }
    removeAny();
  }
}
