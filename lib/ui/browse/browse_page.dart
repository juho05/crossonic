import 'package:auto_route/auto_route.dart';
import 'package:crossonic/routing/router.gr.dart';
import 'package:crossonic/ui/browse/browse_grid.dart';
import 'package:crossonic/ui/browse/browse_viewmodel.dart';
import 'package:crossonic/ui/common/album_list_item.dart';
import 'package:crossonic/ui/common/artist_list_item.dart';
import 'package:crossonic/ui/common/dialogs/add_to_playlist.dart';
import 'package:crossonic/ui/common/dialogs/chooser.dart';
import 'package:crossonic/ui/common/song_list_item.dart';
import 'package:crossonic/ui/common/toast.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> with RestorationMixin {
  late final BrowseViewModel _viewModel;

  final _controller = RestorableTextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _viewModel = BrowseViewModel(
      subsonicRepository: context.read(),
      audioHandler: context.read(),
    );
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _controller.value.selection = TextSelection(
            baseOffset: 0, extentOffset: _controller.value.text.length);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Builder(builder: (context) {
        return SingleChildScrollView(
          child: Column(
            children: [
              StreamBuilder<bool>(
                  stream: _viewModel.emptySearchStream,
                  builder: (context, snapshot) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: TextField(
                        controller: _controller.value,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          labelText: "Search",
                          icon: Icon(Icons.search),
                          suffixIcon: !(snapshot.data ?? false)
                              ? IconButton(
                                  icon: Icon(Icons.clear),
                                  onPressed: () {
                                    _controller.value.clear();
                                    _viewModel.updateSearchText("");
                                    _focusNode.unfocus();
                                  },
                                )
                              : null,
                        ),
                        restorationId: "browse_page_search_input",
                        onChanged: (value) {
                          _viewModel.updateSearchText(value);
                        },
                        onTapOutside: (event) {
                          _focusNode.unfocus();
                        },
                      ),
                    );
                  }),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  if (!_viewModel.searchMode) {
                    return BrowseGrid();
                  }
                  if (_viewModel.searchStatus == FetchStatus.failure) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: const Icon(Icons.wifi_off),
                    );
                  }
                  if (_viewModel.searchStatus != FetchStatus.success) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: const CircularProgressIndicator.adaptive(),
                    );
                  }
                  if (_viewModel.artists.isEmpty &&
                      _viewModel.albums.isEmpty &&
                      _viewModel.songs.isEmpty) {
                    return const Text("No results");
                  }
                  return Column(
                    children: [
                      if (_viewModel.artists.isNotEmpty)
                        BrowseSearchResultSeparator(
                          title: "Artists",
                          icon: Icons.person,
                        ),
                      ...List<Widget>.generate(
                        _viewModel.artists.length,
                        (index) {
                          final a = _viewModel.artists[index];
                          return ArtistListItem(
                            id: a.id,
                            name: a.name,
                            albumCount: a.albumCount,
                            coverId: a.coverId,
                            onTap: () {
                              context.router.push(ArtistRoute(artistId: a.id));
                            },
                            onPlay: () async {
                              final result = await _viewModel.playArtist(a);
                              if (!context.mounted) return;
                              toastResult(context, result);
                            },
                            onShuffle: (shuffleSongs) async {
                              final result = await _viewModel.playArtist(a,
                                  shuffleAlbums: !shuffleSongs,
                                  shuffleSongs: shuffleSongs);
                              if (!context.mounted) return;
                              toastResult(context, result);
                            },
                            onAddToPlaylist: () async {
                              final result = await _viewModel.getArtistSongs(a);
                              if (!context.mounted) return;
                              switch (result) {
                                case Err():
                                  toastResult(context, result);
                                case Ok():
                                  AddToPlaylistDialog.show(
                                      context, a.name, result.value);
                              }
                            },
                            onAddToQueue: (priority) async {
                              final result = await _viewModel.addArtistToQueue(
                                  a, priority);
                              if (!context.mounted) return;
                              toastResult(context, result,
                                  successMsg: "Added '${a.name}' to ${priority ? "priority " : ""}queue");
                            },
                          );
                        },
                      ),
                      if (_viewModel.albums.isNotEmpty)
                        BrowseSearchResultSeparator(
                          title: "Albums",
                          icon: Icons.album,
                        ),
                      ...List<Widget>.generate(
                        _viewModel.albums.length,
                        (index) {
                          final a = _viewModel.albums[index];
                          return AlbumListItem(
                            id: a.id,
                            name: a.name,
                            songCount: a.songCount,
                            coverId: a.coverId,
                            artist: a.displayArtist,
                            year: a.year,
                            onTap: () {
                              context.router.push(AlbumRoute(albumId: a.id));
                            },
                            onPlay: () async {
                              final result = await _viewModel.playAlbum(a);
                              if (!context.mounted) return;
                              toastResult(context, result);
                            },
                            onShuffle: () async {
                              final result =
                                  await _viewModel.playAlbum(a, shuffle: true);
                              if (!context.mounted) return;
                              toastResult(context, result);
                            },
                            onAddToPlaylist: () async {
                              final result = await _viewModel.getAlbumSongs(a);
                              if (!context.mounted) return;
                              switch (result) {
                                case Err():
                                  toastResult(context, result);
                                case Ok():
                                  AddToPlaylistDialog.show(
                                      context, a.name, result.value);
                              }
                            },
                            onAddToQueue: (priority) async {
                              final result =
                                  await _viewModel.addAlbumToQueue(a, priority);
                              if (!context.mounted) return;
                              toastResult(context, result,
                                  successMsg: "Added '${a.name}' to ${priority ? "priority " : ""}queue");
                            },
                            onGoToArtist: a.artists.isNotEmpty
                                ? () async {
                                    final artistId =
                                        await ChooserDialog.chooseArtist(
                                            context, a.artists.toList());
                                    if (artistId == null || !context.mounted)
                                      return;
                                    context.router
                                        .push(ArtistRoute(artistId: artistId));
                                  }
                                : null,
                          );
                        },
                      ),
                      if (_viewModel.songs.isNotEmpty)
                        BrowseSearchResultSeparator(
                          title: "Songs",
                          icon: Icons.music_note,
                        ),
                      ...List<Widget>.generate(
                        _viewModel.songs.length,
                        (index) {
                          final s = _viewModel.songs[index];
                          return SongListItem(
                            id: s.id,
                            title: s.title,
                            coverId: s.coverId,
                            artist: s.displayArtist,
                            duration: s.duration,
                            year: s.year,
                            onTap: (ctrlPressed) {
                              _viewModel.playSong(index, ctrlPressed);
                            },
                            onAddToPlaylist: () {
                              AddToPlaylistDialog.show(context, s.title, [s]);
                            },
                            onAddToQueue: (priority) {
                              _viewModel.addSongToQueue(s, priority);
                              Toast.show(context,
                                  "Added '${s.title}' to ${priority ? "priority " : ""}queue");
                            },
                            onGoToAlbum: s.album != null
                                ? () {
                                    context.router
                                        .push(AlbumRoute(albumId: s.album!.id));
                                  }
                                : null,
                            onGoToArtist: s.artists.isNotEmpty
                                ? () async {
                                    final artistId =
                                        await ChooserDialog.chooseArtist(
                                            context, s.artists.toList());
                                    if (artistId == null || !context.mounted)
                                      return;
                                    context.router
                                        .push(ArtistRoute(artistId: artistId));
                                  }
                                : null,
                          );
                        },
                      ),
                    ],
                  );
                },
              )
            ],
          ),
        );
      }),
    );
  }

  @override
  String? get restorationId => "browse_page";

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_controller, "browse_page_search_controller");
  }
}

class BrowseSearchResultSeparator extends StatelessWidget {
  final String title;
  final IconData icon;
  const BrowseSearchResultSeparator({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        spacing: 8,
        children: [
          Icon(icon),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          )
        ],
      ),
    );
  }
}
