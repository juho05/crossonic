import 'package:crossonic/ui/common/context_menu_button.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';

class CoverArtDecorated extends StatefulWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;

  final bool isFavorite;

  final Iterable<ContextMenuOption> menuOptions;

  const CoverArtDecorated({
    super.key,
    this.coverId,
    required this.placeholderIcon,
    required this.borderRadius,
    required this.isFavorite,
    this.menuOptions = const [],
  });

  @override
  State<CoverArtDecorated> createState() => _CoverArtDecoratedState();
}

class _CoverArtDecoratedState extends State<CoverArtDecorated> {
  bool get _showMenu => widget.menuOptions.isNotEmpty;

  final _popupMenuButton = GlobalKey<State>();

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        CoverArt(
          placeholderIcon: widget.placeholderIcon,
          borderRadius: widget.borderRadius,
          coverId: widget.coverId,
        ),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final largeLayout = constraints.maxHeight >= 256;
              return Padding(
                padding: EdgeInsets.all(largeLayout ? 10 : 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Visibility(
                          visible: widget.isFavorite,
                          child: DecoratedIcon(
                            decoration: IconDecoration(
                              border: IconBorder(
                                color: Theme.of(context).colorScheme.primary,
                                width: 4,
                              ),
                            ),
                            icon: Icon(
                              Icons.favorite,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black45),
                              ],
                              size: largeLayout ? 26 : 20,
                              color: const Color.fromARGB(255, 248, 248, 248),
                            ),
                          ),
                        ),
                        SizedBox.shrink(),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox.shrink(),
                        Visibility(
                          visible: _showMenu,
                          child: Material(
                            type: MaterialType.transparency,
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: Colors.black.withAlpha(90),
                                shape: const CircleBorder(),
                              ),
                              child: SizedBox(
                                width: largeLayout ? 40 : 30,
                                height: largeLayout ? 40 : 30,
                                child: ContextMenuButton(
                                  popupMenuButtonKey: _popupMenuButton,
                                  options: widget.menuOptions,
                                  padding: const EdgeInsets.all(0),
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: largeLayout ? 26 : 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
    if (_showMenu) {
      return WithContextMenu(
        options: widget.menuOptions,
        popupMenuButtonKey: _popupMenuButton,
        child: child,
      );
    }
    return child;
  }
}
