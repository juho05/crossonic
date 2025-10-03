import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/album_grid_cell.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/ui/home/components/release_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeReleaseList extends StatelessWidget {
  final String title;
  final PageRouteInfo? route;

  const HomeReleaseList({
    super.key,
    required this.title,
    required this.route,
  });

  static const double _itemHeight = 180;

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: title,
      route: route,
      sliver: Consumer<HomeReleaseListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == FetchStatus.failure) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: Icon(Icons.wifi_off),
                ),
              ),
            );
          }
          if (viewModel.status != FetchStatus.success) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            );
          }
          final albums = viewModel.albums;
          if (albums.isEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: _itemHeight,
                child: Center(
                  child: Text("No releases found"),
                ),
              ),
            );
          }
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: SizedBox(
                height: _itemHeight,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: albums.length,
                  itemExtent: _itemHeight * (4.0 / 5),
                  itemBuilder: (context, index) {
                    final a = albums[index];
                    return AspectRatio(
                      key: ValueKey("${a.id}-$index"),
                      aspectRatio: 4.0 / 5,
                      child: AlbumGridCell(
                        album: a,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
