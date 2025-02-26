import 'package:flutter/material.dart';

class ClickableListItem extends StatelessWidget {
  final String title;
  final bool titleBold;
  final Iterable<String> extraInfo;
  final Widget? leading;
  final Widget? trailing;
  final String? trailingInfo;
  final void Function()? onTap;
  final bool isFavorite;

  const ClickableListItem({
    super.key,
    required this.title,
    this.titleBold = false,
    this.extraInfo = const [],
    this.leading,
    this.trailing,
    this.trailingInfo,
    this.onTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: leading,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium!.copyWith(
                    fontSize: 15,
                    fontWeight: titleBold ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (extraInfo.isNotEmpty)
                  Text(
                    extraInfo.join(" • "),
                    style: textTheme.bodySmall!
                        .copyWith(fontWeight: FontWeight.w300, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (isFavorite) const Icon(Icons.favorite, size: 15),
          if (trailingInfo != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                trailingInfo!,
                style: textTheme.bodySmall,
              ),
            ),
        ],
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.only(left: 4, right: 4),
    );
  }
}
