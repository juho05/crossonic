import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/main/layout_mode.dart';
import 'package:flutter/material.dart';

class CollectionExtraInfo {
  final String text;
  final String? badgeText;
  final void Function()? onClick;

  CollectionExtraInfo({required this.text, this.onClick, this.badgeText});
}

class CollectionAction {
  final String title;
  final IconData? icon;
  final bool highlighted;
  final void Function() onClick;
  final Color? color;

  CollectionAction({
    required this.title,
    this.icon,
    this.highlighted = false,
    this.color,
    required this.onClick,
  });
}

class CollectionPage extends StatelessWidget {
  final Widget? contentSliver;
  final String? contentTitle;
  final bool showContentTitleInMobileView;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final bool loadingDescription;
  final String? description;
  final String descriptionTitle;
  final void Function()? onChangeName;
  final void Function()? onChangeDescription;

  const CollectionPage({
    super.key,
    this.contentSliver,
    this.contentTitle,
    this.showContentTitleInMobileView = false,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.loadingDescription = false,
    this.description,
    this.descriptionTitle = "About",
    this.onChangeName,
    this.onChangeDescription,
  });

  @override
  Widget build(BuildContext context) {
    final desc = description == null || description!.isEmpty
        ? null
        : description;
    return LayoutModeBuilder(
      builder: (context, isDesktop) {
        if (isDesktop) {
          return CollectionPageDesktop(
            contentSliver: contentSliver,
            contentTitle: contentTitle,
            cover: cover,
            name: name,
            extraInfo: extraInfo,
            actions: actions,
            loadingDescription: loadingDescription,
            description: desc,
            onChangeName: onChangeName,
            onChangeDescription: onChangeDescription,
            descriptionTitle: descriptionTitle,
          );
        } else {
          return CollectionPageMobile(
            contentSliver: contentSliver,
            contentTitle: showContentTitleInMobileView ? contentTitle : null,
            cover: cover,
            name: name,
            extraInfo: extraInfo,
            actions: actions,
            loadingDescription: loadingDescription,
            description: desc,
            onChangeName: onChangeName,
            onChangeDescription: onChangeDescription,
            descriptionTitle: descriptionTitle,
          );
        }
      },
    );
  }
}

class CollectionPageMobile extends StatefulWidget {
  final Widget? contentSliver;
  final String? contentTitle;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final bool loadingDescription;
  final String? description;
  final String descriptionTitle;
  final void Function()? onChangeName;
  final void Function()? onChangeDescription;

  const CollectionPageMobile({
    super.key,
    this.contentSliver,
    this.contentTitle,
    this.cover,
    required this.name,
    required this.descriptionTitle,
    this.extraInfo,
    this.actions,
    this.loadingDescription = false,
    this.description,
    this.onChangeName,
    this.onChangeDescription,
  });

  @override
  State<CollectionPageMobile> createState() => _CollectionPageMobileState();
}

class _CollectionPageMobileState extends State<CollectionPageMobile> {
  bool _descriptionOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 10),
              sliver: SliverList.list(
                children: [
                  if (widget.cover != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: constraints.maxHeight * 0.6,
                        ),
                        child: widget.cover!,
                      ),
                    ),
                  if (widget.cover != null) const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Tooltip(
                            message: widget.name,
                            waitDuration: const Duration(milliseconds: 500),
                            child: Text(
                              widget.name,
                              style: Theme.of(context).textTheme.bodyLarge!
                                  .copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 22,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        if (widget.onChangeName != null)
                          GestureDetector(
                            onTap: widget.onChangeName,
                            child: const Tooltip(
                              message: "Change name",
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit, size: 18),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (widget.extraInfo != null)
                    ...widget.extraInfo!.map(
                      (i) => _ExtraInfoWidget(extraInfo: i),
                    ),
                  if (widget.actions != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 10,
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.actions!.map((element) {
                          return Button(
                            icon: element.icon,
                            onPressed: element.onClick,
                            outlined: !element.highlighted,
                            color: element.color,
                            child: Text(
                              element.title,
                              style: element.color != null
                                  ? Theme.of(context).textTheme.bodyMedium!
                                        .copyWith(color: element.color)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (widget.contentTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        widget.contentTitle!,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall!.copyWith(fontSize: 20),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.contentSliver != null) widget.contentSliver!,
            if (widget.description == null &&
                widget.onChangeDescription != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: Button(
                      icon: Icons.add,
                      onPressed: widget.onChangeDescription,
                      outlined: true,
                      child: const Text("Add description"),
                    ),
                  ),
                ),
              ),
            if (widget.description != null)
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList.list(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          widget.descriptionTitle,
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (widget.onChangeDescription != null)
                          GestureDetector(
                            onTap: widget.onChangeDescription,
                            child: const Tooltip(
                              message: "Change description",
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.edit, size: 20),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        constraints: _descriptionOpen
                            ? null
                            : const BoxConstraints(maxHeight: 182),
                        child: Text(widget.description!),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () => setState(() {
                          _descriptionOpen = !_descriptionOpen;
                        }),
                        child: Text(
                          _descriptionOpen ? "show less" : "show more",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.loadingDescription)
              const SliverPadding(
                padding: EdgeInsets.only(top: 12),
                sliver: SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class CollectionPageDesktop extends StatefulWidget {
  final Widget? contentSliver;
  final String? contentTitle;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final bool loadingDescription;
  final String? description;
  final String descriptionTitle;
  final void Function()? onChangeName;
  final void Function()? onChangeDescription;

  const CollectionPageDesktop({
    super.key,
    this.contentSliver,
    this.contentTitle,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.loadingDescription = false,
    this.description,
    required this.descriptionTitle,
    this.onChangeName,
    this.onChangeDescription,
  });

  @override
  State<CollectionPageDesktop> createState() => _CollectionPageDesktopState();
}

class _CollectionPageDesktopState extends State<CollectionPageDesktop> {
  bool _descriptionOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: constraints.maxWidth < 1200 ? 3 : 0,
              child: SizedBox(
                width: constraints.maxWidth >= 1200 ? 450 : null,
                child: Column(
                  children: [
                    if (widget.cover != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: widget.cover!,
                      ),
                    if (widget.cover != null) const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 4,
                        children: [
                          Flexible(
                            child: Tooltip(
                              message: widget.name,
                              waitDuration: const Duration(milliseconds: 500),
                              child: Text(
                                widget.name,
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 22,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          if (widget.onChangeName != null)
                            GestureDetector(
                              onTap: widget.onChangeName,
                              child: const Tooltip(
                                message: "Change name",
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Padding(
                                    padding: EdgeInsets.all(4),
                                    child: Icon(Icons.edit, size: 18),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.extraInfo != null)
                      ...widget.extraInfo!.map(
                        (i) => _ExtraInfoWidget(extraInfo: i),
                      ),
                    if (widget.loadingDescription)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                    if (widget.description == null &&
                        widget.onChangeDescription != null)
                      Expanded(
                        child: Center(
                          child: Button(
                            icon: Icons.add,
                            onPressed: widget.onChangeDescription,
                            outlined: true,
                            child: const Text("Add description"),
                          ),
                        ),
                      ),
                    if (widget.description != null)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    widget.descriptionTitle,
                                    textAlign: TextAlign.start,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall!
                                        .copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  if (widget.onChangeDescription != null)
                                    GestureDetector(
                                      onTap: widget.onChangeDescription,
                                      child: const Tooltip(
                                        message: "Change description",
                                        child: MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: Padding(
                                            padding: EdgeInsets.all(4),
                                            child: Icon(Icons.edit, size: 20),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        constraints: _descriptionOpen
                                            ? null
                                            : const BoxConstraints(
                                                maxHeight: 182,
                                              ),
                                        child: Text(widget.description!),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: TextButton(
                                          onPressed: () => setState(() {
                                            _descriptionOpen =
                                                !_descriptionOpen;
                                          }),
                                          child: Text(
                                            _descriptionOpen
                                                ? "show less"
                                                : "show more",
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              flex: 5,
              child: CustomScrollView(
                slivers: [
                  SliverList.list(
                    children: [
                      if (widget.contentTitle != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            widget.contentTitle!,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineSmall!.copyWith(fontSize: 20),
                          ),
                        ),
                      if (widget.actions != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 10,
                            bottom: 4,
                          ),
                          child: SizedBox(
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.actions!.map((element) {
                                return Button(
                                  icon: element.icon,
                                  onPressed: element.onClick,
                                  outlined: !element.highlighted,
                                  color: element.color,
                                  child: Text(
                                    element.title,
                                    style: element.color != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyMedium!.copyWith(
                                            color: element.highlighted
                                                ? Colors.white
                                                : element.color,
                                          )
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (widget.contentSliver != null) widget.contentSliver!,
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ExtraInfoWidget extends StatelessWidget {
  final CollectionExtraInfo _extraInfo;

  const _ExtraInfoWidget({required CollectionExtraInfo extraInfo})
    : _extraInfo = extraInfo;

  @override
  Widget build(BuildContext context) {
    Widget text = Tooltip(
      message: _extraInfo.text,
      waitDuration: const Duration(milliseconds: 500),
      child: Text(
        _extraInfo.text,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
      ),
    );

    final badgeColor = Theme.of(context).colorScheme.secondaryContainer;
    final badgeForeground = Theme.of(context).colorScheme.onSecondaryContainer;

    if (_extraInfo.badgeText != null) {
      text = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: 6,
        children: [
          text,
          Container(
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(120),
              border: Border.all(color: badgeColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _extraInfo.badgeText!,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: badgeForeground,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: _extraInfo.onClick != null
          ? Align(
              alignment: Alignment.center,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Material(
                  child: InkWell(
                    onTap: _extraInfo.onClick,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 32,
                      ),
                      child: text,
                    ),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: text,
            ),
    );
  }
}
