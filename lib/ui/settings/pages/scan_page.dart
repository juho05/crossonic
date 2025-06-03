import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/settings/pages/scan_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/result_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late final ScanViewModel _viewModel;
  @override
  void initState() {
    super.initState();
    _viewModel = ScanViewModel(subsonic: context.read());
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
        title: const Text("Scan"),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Scanned: ${_viewModel.scannedCount ?? "unknown"}"),
                const SizedBox(height: 15),
                Button(
                  onPressed: !_viewModel.scanning
                      ? () async {
                          final result = await _viewModel.scan();
                          if (!context.mounted) return;
                          toastResult(context, result);
                        }
                      : null,
                  darkTonal: true,
                  child: _viewModel.scanning
                      ? const Text("Scanning…")
                      : const Text("Rescan"),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
