import 'package:flutter/material.dart';

class CollectionExtraInfo {
  final String text;
  final void Function()? onClick;

  CollectionExtraInfo({required this.text, this.onClick});
}

class CollectionAction {
  final String title;
  final IconData? icon;
  final void Function() onClick;

  CollectionAction({required this.title, this.icon, required this.onClick});
}

class CollectionPage extends StatelessWidget {
  final Widget? content;
  final Widget Function(BuildContext context, int index)?
      reorderableItemBuilder;
  final int? reorderableItemCount;
  final String? contentTitle;
  final bool showContentTitleInMobileView;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool loadingDescription;
  final String? description;

  const CollectionPage({
    super.key,
    this.content,
    this.reorderableItemBuilder,
    this.reorderableItemCount,
    this.contentTitle,
    this.showContentTitleInMobileView = false,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.onReorder,
    this.loadingDescription = false,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.landscape) {
        return CollectionPageDesktop(
          content: content,
          reorderableItemBuilder: reorderableItemBuilder,
          reorderableItemCount: reorderableItemCount,
          onReorder: onReorder,
          contentTitle: contentTitle,
          cover: cover,
          name: name,
          extraInfo: extraInfo,
          actions: actions,
          loadingDescription: loadingDescription,
          description: description,
        );
      } else {
        return CollectionPageMobile(
          content: content,
          reorderableItemBuilder: reorderableItemBuilder,
          reorderableItemCount: reorderableItemCount,
          onReorder: onReorder,
          contentTitle: showContentTitleInMobileView ? contentTitle : null,
          cover: cover,
          name: name,
          extraInfo: extraInfo,
          actions: actions,
          loadingDescription: loadingDescription,
          description: description,
        );
      }
    });
  }
}

class CollectionPageMobile extends StatelessWidget {
  final Widget? content;
  final Widget Function(BuildContext context, int index)?
      reorderableItemBuilder;
  final int? reorderableItemCount;
  final String? contentTitle;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool loadingDescription;
  final String? description;

  const CollectionPageMobile({
    super.key,
    this.content,
    this.reorderableItemBuilder,
    this.reorderableItemCount,
    this.contentTitle,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.onReorder,
    this.loadingDescription = false,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return ReorderableListView.builder(
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (cover != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(maxHeight: constraints.maxHeight * 0.6),
                  child: cover!,
                ),
              ),
            if (cover != null) const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                name,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                    ),
              ),
            ),
            if (extraInfo != null)
              ...extraInfo!.map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: i.onClick != null
                      ? TextButton(
                          onPressed: i.onClick,
                          child: Text(
                            i.text,
                            overflow: TextOverflow.ellipsis,
                            style:
                                Theme.of(context).textTheme.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15,
                                    ),
                          ),
                        )
                      : Text(
                          i.text,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 15,
                                  ),
                        ),
                ),
              ),
            if (actions != null) const SizedBox(height: 10),
            if (actions != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: actions!.map((element) {
                      if (element.icon != null) {
                        return ElevatedButton.icon(
                          icon: Icon(element.icon!),
                          onPressed: element.onClick,
                          label: Text(element.title),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: element.onClick,
                          child: Text(element.title),
                        );
                      }
                    }).toList()),
              ),
            const SizedBox(height: 10),
            if (contentTitle != null)
              Text(
                contentTitle!,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(fontSize: 20),
              ),
            if (contentTitle != null) const SizedBox(height: 10),
            if (content != null) content!,
            if (loadingDescription)
              Center(child: CircularProgressIndicator.adaptive()),
            if (description != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: DescriptionTextWidget(
                  text: description!,
                  enableScroll: false,
                ),
              ),
          ],
        ),
        itemBuilder: reorderableItemBuilder ??
            (BuildContext context, int index) => const SizedBox(),
        itemCount: reorderableItemCount ?? 0,
        onReorder: onReorder ?? (int oldIndex, int newIndex) {},
        buildDefaultDragHandles: false,
      );
    });
  }
}

class CollectionPageDesktop extends StatelessWidget {
  final Widget? content;
  final Widget Function(BuildContext context, int index)?
      reorderableItemBuilder;
  final int? reorderableItemCount;
  final String? contentTitle;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final void Function(int oldIndex, int newIndex)? onReorder;
  final bool loadingDescription;
  final String? description;

  const CollectionPageDesktop({
    super.key,
    this.content,
    this.reorderableItemBuilder,
    this.reorderableItemCount,
    this.contentTitle,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.onReorder,
    this.loadingDescription = false,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: constraints.maxWidth < 1200 ? 3 : 0,
            child: SizedBox(
              width: constraints.maxWidth >= 1200 ? 450 : null,
              child: Column(
                children: [
                  if (cover != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: cover!,
                    ),
                  if (cover != null) const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                    ),
                  ),
                  if (extraInfo != null)
                    ...extraInfo!.map(
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: i.onClick != null
                            ? TextButton(
                                onPressed: i.onClick,
                                child: Text(
                                  i.text,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .copyWith(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15,
                                      ),
                                ),
                              )
                            : Text(
                                i.text,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 15,
                                    ),
                              ),
                      ),
                    ),
                  if (loadingDescription)
                    Expanded(
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  if (description != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DescriptionTextWidget(text: description!),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            flex: 5,
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              onReorder: onReorder ?? (int oldIndex, int newIndex) {},
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (contentTitle != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        contentTitle!,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall!
                            .copyWith(fontSize: 20),
                      ),
                    ),
                  if (actions != null) const SizedBox(height: 10),
                  if (actions != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        child: Wrap(
                            alignment: WrapAlignment.start,
                            spacing: 8,
                            runSpacing: 8,
                            children: actions!.map((element) {
                              if (element.icon != null) {
                                return ElevatedButton.icon(
                                  icon: Icon(element.icon!),
                                  onPressed: element.onClick,
                                  label: Text(element.title),
                                );
                              } else {
                                return ElevatedButton(
                                  onPressed: element.onClick,
                                  child: Text(element.title),
                                );
                              }
                            }).toList()),
                      ),
                    ),
                  if (actions != null) const SizedBox(height: 4),
                  if (content != null) content!,
                ],
              ),
              itemBuilder: reorderableItemBuilder ??
                  (BuildContext context, int index) => const SizedBox(),
              itemCount: reorderableItemCount ?? 0,
            ),
          ),
        ],
      );
    });
  }
}

class DescriptionTextWidget extends StatefulWidget {
  final String text;
  final bool enableScroll;
  const DescriptionTextWidget(
      {super.key, required this.text, this.enableScroll = true});

  @override
  State<DescriptionTextWidget> createState() => _DescriptionTextWidgetState();
}

class _DescriptionTextWidgetState extends State<DescriptionTextWidget> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        Container(
          constraints: open ? null : const BoxConstraints(maxHeight: 182),
          child: Text(widget.text),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: TextButton(
            onPressed: () => setState(() {
              open = !open;
            }),
            child: Text(open ? "show less" : "show more"),
          ),
        )
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About",
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(fontSize: 24, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        if (widget.enableScroll)
          Expanded(
            child: SingleChildScrollView(
              child: column,
            ),
          ),
        if (!widget.enableScroll) column,
      ],
    );
  }
}
