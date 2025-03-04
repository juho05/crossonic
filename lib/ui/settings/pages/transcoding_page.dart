import 'package:auto_route/auto_route.dart';
import 'package:crossonic/data/repositories/settings/transcoding.dart';
import 'package:crossonic/ui/settings/pages/transcoding_viewmodel.dart';
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
        title: Text("Transcoding"),
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
                                "Server Default",
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
                                  : "Server Default",
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
                                  "Server Default",
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
                    initialSelection: _viewModel.maxBitRate,
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
                                  : "Server Default",
                            ))
                        .toList(),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    _viewModel.reset();
                  },
                  icon: Icon(Icons.settings_backup_restore),
                  label: Text("Reset"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
