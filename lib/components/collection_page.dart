import 'package:crossonic/components/state/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  final Widget? extraContent;
  final void Function(int oldIndex, int newIndex)? onReorder;

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
    this.extraContent,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.read<Layout>();
    return LayoutBuilder(builder: (context, constraints) {
      if (layout.size == LayoutSize.desktop) {
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
          extraContent: extraContent,
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
          extraContent: extraContent,
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
  final Widget? extraContent;
  final void Function(int oldIndex, int newIndex)? onReorder;

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
    this.extraContent,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      header: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (cover != null) cover!,
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
          ],
        ),
      ),
      itemBuilder: reorderableItemBuilder ??
          (BuildContext context, int index) => const SizedBox(),
      itemCount: reorderableItemCount ?? 0,
      onReorder: onReorder ?? (int oldIndex, int newIndex) {},
      buildDefaultDragHandles: false,
    );
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
  final Widget? extraContent;
  final void Function(int oldIndex, int newIndex)? onReorder;

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
    this.extraContent,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
            flex: 3,
            child: SingleChildScrollView(
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
                  if (actions != null) const SizedBox(height: 10),
                  if (actions != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
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
                    ),
                ],
              ),
            )),
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
  }
}
