import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/clickable_list_item.dart';
import 'package:crossonic/ui/common/song_list_sliver.dart';
import 'package:crossonic/ui/home/components/home_page_component.dart';
import 'package:crossonic/ui/home/components/song_list_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeSongList extends StatelessWidget {
  final String title;
  final PageRouteInfo? route;

  const HomeSongList({
    super.key,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return HomePageComponent(
      text: title,
      route: route,
      sliver: Consumer<HomeSongListViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.status == FetchStatus.failure) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent * 10,
                child: Center(
                  child: Icon(Icons.wifi_off),
                ),
              ),
            );
          }
          if (viewModel.status != FetchStatus.success) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent * 10,
                child: Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
              ),
            );
          }
          final songs = viewModel.songs;
          if (songs.isEmpty) {
            return const SliverToBoxAdapter(
              child: SizedBox(
                height: ClickableListItem.verticalExtent,
                child: Center(
                  child: Text("No songs found"),
                ),
              ),
            );
          }
          return SongListSliver(songs: songs);
        },
      ),
    );
  }
}
