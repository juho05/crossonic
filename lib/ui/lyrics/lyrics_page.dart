import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/lyrics/lyrics_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: Text("Lyrics"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.status == FetchStatus.failure) {
            return const Center(child: Icon(Icons.wifi_off));
          }
          if (_viewModel.status != FetchStatus.success) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (_viewModel.currentSong == null) {
            return const Center(child: Text("No active song"));
          }
          if (_viewModel.lyrics.isEmpty) {
            return const Center(child: Text("No lyrics"));
          }
          final textTheme = Theme.of(context).textTheme;
          return Padding(
            padding:
                const EdgeInsets.only(left: 8, right: 8, bottom: 32, top: 8),
            child: ListView.builder(
              itemCount: 1 + _viewModel.lyrics.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 2,
                      bottom: 12,
                    ),
                    child: Text(
                      "Song: ${_viewModel.currentSong!.title}",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                    ),
                  );
                }
                index--;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _viewModel.lyrics[index],
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: textTheme.headlineMedium!.copyWith(fontSize: 24),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
