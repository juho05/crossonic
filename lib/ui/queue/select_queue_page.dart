import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/dialogs/confirmation.dart';
import 'package:crossonic/ui/common/search_input.dart';
import 'package:crossonic/ui/queue/select_queue_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class SelectQueuePage extends StatelessWidget {
  const SelectQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SelectQueueViewModel(audioHandler: context.read()),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text("Select Queue")),
          body: SafeArea(
            child: Consumer<SelectQueueViewModel>(
              builder: (context, viewModel, _) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverToBoxAdapter(
                      child: SearchInput(
                        onSearch: (query) {
                          viewModel.filter = query.trim();
                        },
                        debounce: const Duration(milliseconds: 250),
                      ),
                    ),
                  ),
                  if (viewModel.queues.isEmpty)
                    const SliverPadding(
                      padding: EdgeInsets.all(8),
                      sliver: SliverToBoxAdapter(
                        child: Text("No queues found"),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 8),
                    sliver: SliverFixedExtentList.builder(
                      itemExtent: ClickableListItem.verticalExtent,
                      itemCount: viewModel.queues.length,
                      itemBuilder: (context, index) {
                        final queue = viewModel.queues[index];
                        final selected = viewModel.currentQueueId == queue.id;
                        return ClickableListItem(
                          title: selected
                              ? "${queue.name} (Current)"
                              : queue.name,
                          extraInfo: [
                            "Songs: ${queue.songCount}",
                            "Position: ${queue.currentIndex + 1}",
                          ],
                          titleBold: selected,
                          trailing: !queue.isDefault
                              ? IconButton(
                                  onPressed: () async {
                                    final confirmation =
                                        await ConfirmationDialog.showYesNo(
                                          context,
                                          message: "Delete '${queue.name}'?",
                                        );
                                    if (confirmation != true) return;
                                    await viewModel.deleteQueue(queue);
                                    if (!context.mounted) return;
                                    if (selected) {
                                      context.pop();
                                    }
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                )
                              : null,
                          onTap: !selected
                              ? () async {
                                  await viewModel.selectQueue(queue);
                                  if (!context.mounted) return;
                                  context.pop();
                                }
                              : null,
                        );
                      },
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
