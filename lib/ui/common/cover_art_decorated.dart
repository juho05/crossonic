import 'package:crossonic/data/repositories/playlist/song_downloader.dart';
import 'package:crossonic/ui/common/menu_button.dart';
import 'package:crossonic/ui/common/cover_art.dart';
import 'package:crossonic/ui/common/with_context_menu.dart';
import 'package:flutter/material.dart';
import 'package:icon_decoration/icon_decoration.dart';

class CoverArtDecorated extends StatefulWidget {
  final String? coverId;
  final IconData placeholderIcon;
  final BorderRadiusGeometry borderRadius;
  final bool uploading;

  final bool isFavorite;
  final DownloadStatus downloadStatus;

  final Iterable<ContextMenuOption> menuOptions;

  const CoverArtDecorated({
    super.key,
    this.coverId,
    required this.placeholderIcon,
    required this.borderRadius,
    required this.isFavorite,
    this.uploading = false,
    this.downloadStatus = DownloadStatus.none,
    this.menuOptions = const [],
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
                                const Shadow(blurRadius: 2, color: Colors.black45),
                              ],
                              size: largeLayout ? 26 : 20,
                              color: const Color.fromARGB(255, 248, 248, 248),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.downloadStatus != DownloadStatus.none,
                          child: DecoratedIcon(
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
                                  : Icons.download_for_offline_outlined,
                              shadows: [
                                const Shadow(blurRadius: 3, color: Colors.black87),
                              ],
                              size: largeLayout ? 26 : 20,
                              color: const Color.fromARGB(255, 248, 248, 248),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox.shrink(),
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
                                child: MenuButton(
                                  options: widget.menuOptions,
                                  padding: const EdgeInsets.all(0),
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: largeLayout ? 26 : 20,
                                    color: Colors.white,
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
        child: child,
      );
    }
    return child;
  }
}
