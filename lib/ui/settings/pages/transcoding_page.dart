import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/settings/pages/transcoding_viewmodel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class TranscodingPage extends StatefulWidget {
  const TranscodingPage({super.key});

  @override
  State<TranscodingPage> createState() => _TranscodingPageState();
}

class _TranscodingPageState extends State<TranscodingPage> {
  late final TranscodingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TranscodingViewModel(settings: context.read());
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
        title: const Text("Transcoding"),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              spacing: 15,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownMenu<TranscodingCodec>(
                  onSelected: (value) {
                    if (value == null) return;
                    _viewModel.updateCodec(value);
                  },
                  expandedInsets: EdgeInsets.zero,
                  initialSelection: _viewModel.codec,
                  requestFocusOnTap: false,
                  enableSearch: false,
                  label: const Text("Format"),
                  dropdownMenuEntries: _viewModel.availableCodecs
                      .map((codec) => DropdownMenuEntry(
                            label: switch (codec) {
                              TranscodingCodec.serverDefault =>
                                "Server default",
                              TranscodingCodec.raw => "Original",
                              TranscodingCodec.mp3 => "MP3",
                              TranscodingCodec.opus => "OGG/Opus",
                              TranscodingCodec.vorbis => "OGG/Vorbis",
                            },
                            value: codec,
                          ))
                      .toList(),
                ),
                if (_viewModel.codec != TranscodingCodec.raw)
                  DropdownMenu<int?>(
                    onSelected: (value) {
                      _viewModel.updateBitRate(value);
                    },
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: _viewModel.maxBitRate,
                    requestFocusOnTap: false,
                    enableSearch: false,
                    label: const Text("Bitrate"),
                    dropdownMenuEntries: ([
                      null,
                      ..._viewModel.codec.validBitRates,
                    ])
                        .map((option) => DropdownMenuEntry(
                              value: option,
                              label: option != null
                                  ? '$option kbps'
                                  : "Server default",
                            ))
                        .toList(),
                  ),
                if (_viewModel.supportsMobile) const SizedBox(height: 15),
                if (_viewModel.supportsMobile)
                  DropdownMenu<TranscodingCodec>(
                    onSelected: (value) {
                      if (value == null) return;
                      _viewModel.updateCodecMobile(value);
                    },
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: _viewModel.codecMobile,
                    requestFocusOnTap: false,
                    enableSearch: false,
                    label: const Text("Format (mobile)"),
                    dropdownMenuEntries: _viewModel.availableCodecs
                        .map((codec) => DropdownMenuEntry(
                              label: switch (codec) {
                                TranscodingCodec.serverDefault =>
                                  "Server default",
                                TranscodingCodec.raw => "Original",
                                TranscodingCodec.mp3 => "MP3",
                                TranscodingCodec.opus => "OGG/Opus",
                                TranscodingCodec.vorbis => "OGG/Vorbis",
                              },
                              value: codec,
                            ))
                        .toList(),
                  ),
                if (_viewModel.supportsMobile &&
                    _viewModel.codecMobile != TranscodingCodec.raw)
                  DropdownMenu<int?>(
                    onSelected: (value) {
                      _viewModel.updateBitRateMobile(value);
                    },
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: _viewModel.maxBitRateMobile,
                    requestFocusOnTap: false,
                    enableSearch: false,
                    label: const Text("Bitrate (mobile)"),
                    dropdownMenuEntries: ([
                      null,
                      ..._viewModel.codecMobile.validBitRates,
                    ])
                        .map((option) => DropdownMenuEntry(
                              value: option,
                              label: option != null
                                  ? '$option kbps'
                                  : "Server default",
                            ))
                        .toList(),
                  ),
                if (kIsWeb &&
                    (_viewModel.codec != TranscodingCodec.raw ||
                        _viewModel.codecMobile != TranscodingCodec.raw))
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        "WARNING: Some browsers (e.g. Safari) don't properly support playback of streamed transcoded media or might not support the chosen codec at all.",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: const Color.fromARGB(255, 244, 163, 0),
                            fontSize: 13),
                      ),
                      Text(
                        "If you notice playback bugs like music suddenly stopping or not transitioning properly to the next song, consider changing the format back to 'Original'.",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: const Color.fromARGB(255, 244, 163, 0),
                            fontSize: 13),
                      ),
                    ],
                  ),
                if (!kIsWeb &&
                    (_viewModel.codec == TranscodingCodec.mp3 ||
                        _viewModel.codecMobile == TranscodingCodec.mp3))
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        "WARNING: MP3 does not support gapless playback properly. Consider changing the format to OGG/Opus or OGG/Vorbis.",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: const Color.fromARGB(255, 244, 163, 0),
                            fontSize: 14),
                      ),
                    ],
                  ),
                Button(
                  onPressed: () {
                    _viewModel.reset();
                  },
                  icon: Icons.settings_backup_restore,
                  outlined: true,
                  child: const Text("Reset"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
