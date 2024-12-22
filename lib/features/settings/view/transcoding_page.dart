import 'dart:io';

import 'package:crossonic/features/settings/state/transcoding_cubit.dart';
import 'package:crossonic/repositories/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TranscodingPage extends StatefulWidget {
  const TranscodingPage({super.key});

  @override
  State<TranscodingPage> createState() => _TranscodingPageState();
}

class _TranscodingPageState extends State<TranscodingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Transcoding'),
      ),
      body: BlocProvider(
        create: (context) => TranscodingCubit(context.read<Settings>()),
        child: BlocBuilder<TranscodingCubit, TranscodingState>(
          builder: (context, state) {
            final options = TranscodingCubit.options;

            const bitrates = [32, 64, 96, 128, 192, 256, 320, 410, 500];
            final wifiFormat = state.wifiFormat ?? "default";
            final minWifiBitRate = options[wifiFormat]!.minBitRate;
            final maxWifiBitRate = options[wifiFormat]!.maxBitRate;
            final mobileFormat = state.mobileFormat ?? "default";
            final minMobileBitRate = options[mobileFormat]!.minBitRate;
            final maxMobileBitRate = options[mobileFormat]!.maxBitRate;

            final supportsMobile = !kIsWeb &&
                (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

            final transcoding = context.read<TranscodingCubit>();
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownMenu<String>(
                    onSelected: (format) {
                      if (format == null) return;
                      transcoding.setWifiFormat(format);
                    },
                    expandedInsets: EdgeInsets.zero,
                    initialSelection: wifiFormat,
                    requestFocusOnTap: false,
                    enableSearch: false,
                    label: const Text("Format"),
                    dropdownMenuEntries: options.values.map((option) {
                      return DropdownMenuEntry<String>(
                        label: option.displayName,
                        value: option.name ?? "default",
                      );
                    }).toList(),
                  ),
                  if (wifiFormat != "raw") const SizedBox(height: 15),
                  if (wifiFormat != "raw")
                    DropdownMenu<int>(
                      onSelected: (bitRate) {
                        if (bitRate == null) return;
                        transcoding
                            .setWifiBitRate(bitRate > 0 ? bitRate : null);
                      },
                      expandedInsets: EdgeInsets.zero,
                      initialSelection: state.wifiBitRate ?? 0,
                      requestFocusOnTap: false,
                      enableSearch: false,
                      label: const Text("Bitrate"),
                      dropdownMenuEntries: ([
                        0,
                        ...bitrates.where((element) {
                          final minValid = minWifiBitRate == null ||
                              element >= minWifiBitRate;
                          final maxValid = maxWifiBitRate == null ||
                              element <= maxWifiBitRate;
                          return minValid && maxValid;
                        })
                      ]).map((option) {
                        return DropdownMenuEntry<int>(
                          label: option > 0 ? '$option kbps' : "Default",
                          value: option,
                        );
                      }).toList(),
                    ),
                  if (supportsMobile) const SizedBox(height: 30),
                  if (supportsMobile)
                    DropdownMenu<String>(
                      onSelected: (format) {
                        if (format == null) return;
                        transcoding.setMobileFormat(format);
                      },
                      expandedInsets: EdgeInsets.zero,
                      initialSelection: mobileFormat,
                      requestFocusOnTap: false,
                      enableSearch: false,
                      label: const Text("Format (mobile)"),
                      dropdownMenuEntries: options.values.map((option) {
                        return DropdownMenuEntry<String>(
                          label: option.displayName,
                          value: option.name ?? "default",
                        );
                      }).toList(),
                    ),
                  if (supportsMobile && mobileFormat != "raw")
                    const SizedBox(height: 15),
                  if (supportsMobile && mobileFormat != "raw")
                    DropdownMenu<int>(
                      onSelected: (bitRate) {
                        if (bitRate == null) return;
                        transcoding
                            .setMobileBitRate(bitRate > 0 ? bitRate : null);
                      },
                      expandedInsets: EdgeInsets.zero,
                      initialSelection: state.mobileBitRate ?? 0,
                      requestFocusOnTap: false,
                      enableSearch: false,
                      label: const Text("Bitrate (mobile)"),
                      dropdownMenuEntries: ([
                        0,
                        ...bitrates.where((element) {
                          final minValid = minMobileBitRate == null ||
                              element >= minMobileBitRate;
                          final maxValid = maxMobileBitRate == null ||
                              element <= maxMobileBitRate;
                          return minValid && maxValid;
                        })
                      ]).map((option) {
                        return DropdownMenuEntry<int>(
                          label: option > 0 ? '$option kbps' : "Default",
                          value: option,
                        );
                      }).toList(),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
