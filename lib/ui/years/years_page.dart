import 'package:auto_route/annotations.dart';
import 'package:crossonic/ui/common/album_grid_sliver.dart';
import 'package:crossonic/ui/years/year_selector_field.dart';
import 'package:crossonic/ui/years/years_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class YearsPage extends StatefulWidget {
  const YearsPage({super.key});

  @override
  State<YearsPage> createState() => _YearsPageState();
}

class _YearsPageState extends State<YearsPage> {
  late final YearsViewModel _viewModel;

  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = YearsViewModel(
      subsonic: context.read(),
    );
    _controller.addListener(_onScroll);
    _viewModel.nextPage();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return CustomScrollView(
            controller: _controller,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Years:",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                      YearSelectorField(
                        year: _viewModel.fromYear,
                        maxYear: DateTime.now().year,
                        onChanged: (year) => _viewModel.fromYear = year,
                      ),
                      const Text("to"),
                      YearSelectorField(
                        year: _viewModel.toYear,
                        minYear: _viewModel.fromYear,
                        onChanged: (year) => _viewModel.toYear = year,
                      ),
                    ],
                  ),
                ),
              ),
              AlbumGridSliver(
                albums: _viewModel.albums,
                fetchStatus: _viewModel.status,
              ),
            ],
          );
        },
      ),
    );
  }

  void _onScroll() {
    if (_isBottom) _viewModel.nextPage();
  }

  bool get _isBottom {
    if (!_controller.hasClients) return false;
    final maxScroll = _controller.position.maxScrollExtent;
    final currentScroll = _controller.offset;
    return currentScroll >= (maxScroll * 0.8);
  }
}
