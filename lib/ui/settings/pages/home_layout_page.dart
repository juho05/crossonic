import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/section_header.dart';
import 'package:crossonic/ui/settings/pages/home_layout_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomeLayoutPage extends StatelessWidget {
  const HomeLayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ChangeNotifierProvider(
      create: (context) => HomeLayoutViewModel(
        settings: context.read<SettingsRepository>().homeLayout,
      ),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Home Layout")),
          body: SafeArea(
            child: Consumer<HomeLayoutViewModel>(
              builder: (context, viewModel, _) {
                return CustomScrollView(
                  slivers: [
                    const SliverPadding(
                      padding: EdgeInsets.all(8.0),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(text: "Active"),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      sliver: SliverReorderableList(
                        itemCount: viewModel.activeComponents.length,
                        itemExtent: ClickableListItem.verticalExtent,
                        itemBuilder: (context, index) {
                          final c = viewModel.activeComponents[index];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey("${c.name}-$index"),
                            index: index,
                            child: ClickableListItem(
                              opaque: true,
                              title: HomeLayoutSettings.optionTitle(c),
                              onTap: () {},
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: const Icon(Icons.drag_handle),
                              ),
                              trailing: IconButton(
                                onPressed: () {
                                  viewModel.remove(index);
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ),
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          viewModel.reorder(oldIndex, newIndex);
                        },
                      ),
                    ),
                    const SliverPadding(
                      padding: EdgeInsets.all(8.0),
                      sliver: SliverToBoxAdapter(
                        child: SectionHeader(text: "Inactive"),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      sliver: SliverFixedExtentList.builder(
                        itemCount: viewModel.inactiveComponents.length,
                        itemExtent: ClickableListItem.verticalExtent,
                        itemBuilder: (context, index) {
                          final c = viewModel.inactiveComponents[index];
                          return ClickableListItem(
                            opaque: true,
                            title: HomeLayoutSettings.optionTitle(c),
                            onTap: () => viewModel.add(index),
                            trailing: IconButton(
                              onPressed: () {
                                viewModel.add(index);
                              },
                              icon: const Icon(Icons.add),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
