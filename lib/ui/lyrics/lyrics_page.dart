import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/lyrics/lyrics_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/lyrics_reader.dart';
import 'package:flutter_lyric/lyrics_reader_model.dart';
import 'package:provider/provider.dart';

@RoutePage()
class LyricsPage extends StatefulWidget {
  const LyricsPage({super.key});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
  late final LyricsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LyricsViewModel(
      subsonic: context.read(),
      audioHandler: context.read(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lyrics")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.status == FetchStatus.failure) {
                return const Center(child: Icon(Icons.wifi_off));
              }
              if (_viewModel.status != FetchStatus.success) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }
              if (_viewModel.currentSong == null) {
                return const Center(child: Text("No active song"));
              }
              if (_viewModel.lyrics == null) {
                return const Center(child: Text("No lyrics"));
              }
              final lyricsModel = LyricsReaderModel();
              lyricsModel.lyrics = _viewModel.lyrics!.lines.map((e) {
                final model = LyricsLineModel();
                model.mainText = e.text;
                model.startTime = e.start?.inMilliseconds;
                model.endTime =
                    e.end?.inMilliseconds ??
                    _viewModel.currentSong?.duration?.inMilliseconds;
                return model;
              }).toList();
              if (!_viewModel.syncedMode) {
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: 32,
                    top: 8,
                  ),
                  child: ListView.builder(
                    itemCount:
                        _viewModel.lyrics!.lines.length +
                        (_viewModel.supportsSync ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_viewModel.supportsSync) {
                        if (index == 0) {
                          return Align(
                            alignment: Alignment.centerRight,
                            child: Button(
                              outlined: !_viewModel.syncedMode,
                              onPressed: () => _viewModel.syncedMode =
                                  !_viewModel.syncedMode,
                              child: Text(
                                _viewModel.syncedMode ? "Synced" : "Unsynced",
                              ),
                            ),
                          );
                        }
                        index--;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _viewModel.lyrics!.lines[index].text,
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: Theme.of(context).textTheme.headlineMedium!
                              .copyWith(
                                fontSize: constraints.maxWidth >= 1000
                                    ? 25
                                    : 18,
                              ),
                        ),
                      );
                    },
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Button(
                        outlined: !_viewModel.syncedMode,
                        onPressed: () =>
                            _viewModel.syncedMode = !_viewModel.syncedMode,
                        child: Text(
                          _viewModel.syncedMode ? "Synced" : "Unsynced",
                        ),
                      ),
                    ),
                    Expanded(
                      child: StreamBuilder(
                        stream: _viewModel.position,
                        builder: (context, _) {
                          return IgnorePointer(
                            // TODO custom lyrics implementation that allows scrolling and clicking on line to seek
                            child: LyricsReader(
                              model: lyricsModel,
                              lyricUi: UINetease(
                                highlight: false,
                                bias: 0.35,
                                defaultSize: constraints.maxWidth >= 1000
                                    ? 35
                                    : 25,
                                otherMainSize: constraints.maxWidth >= 1000
                                    ? 25
                                    : 18,
                              ),
                              playing: _viewModel.playing,
                              position:
                                  _viewModel.position.value.inMilliseconds,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
