import 'package:crossonic/ui/common/buttons.dart';
import 'package:flutter/material.dart';

class CollectionExtraInfo {
  final String text;
  final void Function()? onClick;

  CollectionExtraInfo({required this.text, this.onClick});
}

class CollectionAction {
  final String title;
  final IconData? icon;
  final bool highlighted;
  final void Function() onClick;

  CollectionAction(
      {required this.title,
      this.icon,
      this.highlighted = false,
      required this.onClick});
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
  });

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.landscape) {
        return CollectionPageDesktop(
          contentSliver: contentSliver,
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
          contentSliver: contentSliver,
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

class CollectionPageMobile extends StatefulWidget {
  final Widget? contentSliver;
  final String? contentTitle;
  final Widget? cover;
  final String name;
  final List<CollectionExtraInfo>? extraInfo;
  final List<CollectionAction>? actions;
  final bool loadingDescription;
  final String? description;

  const CollectionPageMobile({
    super.key,
    this.contentSliver,
    this.contentTitle,
    this.cover,
    required this.name,
    this.extraInfo,
    this.actions,
    this.loadingDescription = false,
    this.description,
  });

  @override
  State<CollectionPageMobile> createState() => _CollectionPageMobileState();
}

class _CollectionPageMobileState extends State<CollectionPageMobile> {
  bool _descriptionOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
                          maxHeight: constraints.maxHeight * 0.6),
                      child: widget.cover!,
                    ),
                  ),
                if (widget.cover != null) const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.name,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.extraInfo != null)
                  ...widget.extraInfo!.map(
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
                              textAlign: TextAlign.center,
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
                if (widget.actions != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 12, right: 12, top: 10),
                    child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.actions!.map((element) {
                          return Button(
                            icon: element.icon,
                            onPressed: element.onClick,
                            outlined: !element.highlighted,
                            child: Text(element.title),
                          );
                        }).toList()),
                  ),
                if (widget.contentTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      widget.contentTitle!,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall!
                          .copyWith(fontSize: 20),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.contentSliver != null) widget.contentSliver!,
          if (widget.description != null)
            SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList.list(children: [
                Text(
                  "About",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontSize: 24, fontWeight: FontWeight.w500),
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
                    child: Text(_descriptionOpen ? "show less" : "show more"),
                  ),
                )
              ]),
            ),
          if (widget.loadingDescription)
            const SliverPadding(
              padding: EdgeInsets.only(top: 12),
              sliver: SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
            )
        ],
      );
    });
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
  });

  @override
  State<CollectionPageDesktop> createState() => _CollectionPageDesktopState();
}

class _CollectionPageDesktopState extends State<CollectionPageDesktop> {
  bool _descriptionOpen = false;

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
                  if (widget.cover != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: widget.cover!,
                    ),
                  if (widget.cover != null) const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      widget.name,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 22,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.extraInfo != null)
                    ...widget.extraInfo!.map(
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
                  if (widget.loadingDescription)
                    const Expanded(
                      child:
                          Center(child: CircularProgressIndicator.adaptive()),
                    ),
                  if (widget.description != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "About",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w500),
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Container(
                                      constraints: _descriptionOpen
                                          ? null
                                          : const BoxConstraints(
                                              maxHeight: 182),
                                      child: Text(widget.description!),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () => setState(() {
                                          _descriptionOpen = !_descriptionOpen;
                                        }),
                                        child: Text(_descriptionOpen
                                            ? "show less"
                                            : "show more"),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(fontSize: 20),
                        ),
                      ),
                    if (widget.actions != null)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 12, right: 12, top: 10, bottom: 4),
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
                                  child: Text(element.title),
                                );
                              }).toList()),
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
    });
  }
}
