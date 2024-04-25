import 'package:crossonic/widgets/cover_art.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Album extends StatelessWidget {
  final String id;
  final String name;
  final String extraInfo;
  final String? coverID;
  const Album({
    super.key,
    required this.id,
    required this.name,
    required this.extraInfo,
    this.coverID,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textTheme = Theme.of(context).textTheme;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.push("/home/album/$id");
            },
            child: SizedBox(
              width: constraints.maxHeight * (4 / 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoverArt(
                    coverID: coverID ?? "",
                    resolution: const CoverResolution.medium(),
                    borderRadius: BorderRadius.circular(7),
                    size: constraints.maxHeight * (4 / 5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: constraints.maxHeight * 0.07,
                    ),
                  ),
                  Text(
                    extraInfo,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.w300,
                      fontSize: constraints.maxHeight * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
