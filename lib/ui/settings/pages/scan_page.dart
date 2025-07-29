import 'package:auto_route/auto_route.dart';
import 'package:crossonic/ui/common/buttons.dart';
import 'package:crossonic/ui/settings/pages/scan_viewmodel.dart';
import 'package:crossonic/utils/fetch_status.dart';
import 'package:crossonic/utils/format.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text("Scanned: ${_viewModel.scanStatus.scanned ?? "unknown"}"),
                if (!_viewModel.scanStatus.scanning &&
                    _viewModel.scanStatus.lastScan != null)
                  Text(
                      "Last scan: ${formatDateTime(_viewModel.scanStatus.lastScan!)}"),
                if (_viewModel.scanStatus.scanStart != null)
                  Text(
                      "Elapsed: ${formatDuration(DateTime.now().difference(_viewModel.scanStatus.scanStart!))}"),
                const SizedBox(height: 8),
                if (!_viewModel.scanStatus.scanning ||
                    !(_viewModel.scanStatus.isFullScan ?? false))
                  Button(
                    onPressed: !_viewModel.scanStatus.scanning
                        ? () async {
                            final result = await _viewModel.scan(false);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          }
                        : null,
                    child: _viewModel.scanStatus.scanning
                        ? const Text("Scanning…")
                        : (_viewModel.supportsScanType
                            ? const Text("Quick Scan")
                            : const Text("Scan")),
                  ),
                if (_viewModel.supportsScanType &&
                    (!_viewModel.scanStatus.scanning ||
                        (_viewModel.scanStatus.isFullScan ?? false)))
                  Button(
                    outlined: true,
                    onPressed: !_viewModel.scanStatus.scanning
                        ? () async {
                            final result = await _viewModel.scan(true);
                            if (!context.mounted) return;
                            toastResult(context, result);
                          }
                        : null,
                    child: _viewModel.scanStatus.scanning
                        ? const Text("Scanning…")
                        : const Text("Full Scan"),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}
