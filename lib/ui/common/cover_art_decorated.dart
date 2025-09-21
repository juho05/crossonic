import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:provider/provider.dart';

class CoverArtDecorated extends StatefulWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;
  final bool uploading;

  final bool isFavorite;
  final DownloadStatus downloadStatus;

  final Iterable<ContextMenuOption> menuOptions;

  final Widget? topLeft;
  final Widget? topRight;
  final Widget? bottomLeft;
  final Widget? bottomRight;

  const CoverArtDecorated({
    super.key,
    this.coverId,
    required this.placeholderIcon,
    required this.borderRadius,
    required this.isFavorite,
    this.uploading = false,
    this.downloadStatus = DownloadStatus.none,
    this.menuOptions = const [],
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  });

  @override
  State<CoverArtDecorated> createState() => _CoverArtDecoratedState();
}

class _CoverArtDecoratedState extends State<CoverArtDecorated> {
  bool get _showMenu => widget.menuOptions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      fit: StackFit.loose,
      alignment: Alignment.center,
      children: [
        if (!widget.uploading)
          CoverArt(
            placeholderIcon: widget.placeholderIcon,
            borderRadius: widget.borderRadius,
            coverId: widget.coverId,
          )
        else
          const AspectRatio(
            aspectRatio: 1,
            child: CircularProgressIndicator.adaptive(),
          ),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Provider<OnCoverIconButtonSize>.value(
                  value: constraints.maxHeight >= 256
                      ? OnCoverIconButtonSize.large
                      : OnCoverIconButtonSize.normal,
                  builder: (context, _) {
                    final size = context.read<OnCoverIconButtonSize>();
                    final largeLayout = size == OnCoverIconButtonSize.large;
                    return Padding(
                      padding: EdgeInsets.all(largeLayout ? 10 : 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Visibility(
                                visible:
                                    widget.isFavorite || widget.topLeft != null,
                                child: widget.topLeft ??
                                    DecoratedIcon(
                                      decoration: IconDecoration(
                                        border: IconBorder(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 4,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.favorite,
                                        shadows: [
                                          const Shadow(
                                              blurRadius: 2,
                                              color: Colors.black45),
                                        ],
                                        size: largeLayout ? 26 : 20,
                                        color: const Color.fromARGB(
                                            255, 248, 248, 248),
                                      ),
                                    ),
                              ),
                              Visibility(
                                visible: widget.downloadStatus !=
                                        DownloadStatus.none ||
                                    widget.topRight != null,
                                child: widget.topRight ??
                                    DecoratedIcon(
                                      decoration: const IconDecoration(
                                        border: IconBorder(
                                          color: Colors.black87,
                                          width: 1,
                                        ),
                                      ),
                                      icon: Icon(
                                        widget.downloadStatus ==
                                                DownloadStatus.downloading
                                            ? Icons.downloading_outlined
                                            : Icons
                                                .download_for_offline_outlined,
                                        shadows: [
                                          const Shadow(
                                              blurRadius: 3,
                                              color: Colors.black87),
                                        ],
                                        size: largeLayout ? 26 : 20,
                                        color: const Color.fromARGB(
                                            255, 248, 248, 248),
                                      ),
                                    ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Visibility(
                                visible: widget.bottomLeft != null,
                                child: widget.bottomLeft ??
                                    const SizedBox.shrink(),
                              ),
                              Visibility(
                                visible:
                                    _showMenu || widget.bottomRight != null,
                                child: widget.bottomRight ??
                                    OnCoverMenuButton(
                                      menuOptions: widget.menuOptions,
                                    ),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  });
            },
          ),
        ),
      ],
    );
    if (_showMenu) {
      return WithContextMenu(
        options: widget.menuOptions,
        child: child,
      );
    }
    return child;
  }
}

enum OnCoverIconButtonSize { normal, large }

class OnCoverIconButton extends StatelessWidget {
  final IconData icon;
  final void Function() onPressed;

  const OnCoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return _OnCoverButton(
      button: IconButton(
        onPressed: onPressed,
        padding: const EdgeInsets.all(0),
        icon: Icon(
          Icons.more_vert,
          size: size == OnCoverIconButtonSize.large ? 26 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class OnCoverMenuButton extends StatelessWidget {
  final Iterable<ContextMenuOption> menuOptions;
  final IconData icon;
  final String? tooltip;

  const OnCoverMenuButton({
    super.key,
    required this.menuOptions,
    this.icon = Icons.more_vert,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return _OnCoverButton(
      button: MenuButton(
        options: menuOptions,
        padding: const EdgeInsets.all(0),
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: size == OnCoverIconButtonSize.large ? 26 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _OnCoverButton extends StatelessWidget {
  final Widget button;

  const _OnCoverButton({
    required this.button,
  });

  @override
  Widget build(BuildContext context) {
    OnCoverIconButtonSize size = OnCoverIconButtonSize.normal;
    try {
      size = context.read<OnCoverIconButtonSize>();
    } catch (_) {}
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(
          color: Colors.black.withAlpha(90),
          shape: const CircleBorder(),
        ),
        child: SizedBox(
          width: size == OnCoverIconButtonSize.large ? 40 : 30,
          height: size == OnCoverIconButtonSize.large ? 40 : 30,
          child: button,
        ),
      ),
    );
  }
}
