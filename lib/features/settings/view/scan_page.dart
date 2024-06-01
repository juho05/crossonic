import 'package:crossonic/features/settings/state/scan_cubit.dart';
import 'package:crossonic/repositories/api/api_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crossonic | Scan'),
      ),
      body: BlocProvider(
        create: (context) =>
            ScanCubit(apiRepository: context.read<APIRepository>()),
        child: BlocBuilder<ScanCubit, ScanState>(
          builder: (context, state) {
            if (state.loadingStatus) {
              return const Center(
                child: CircularProgressIndicator.adaptive(),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text("Scanned: ${state.scannedCount ?? "unknown"}"),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    child: state.scanning
                        ? const Text("Scanning…")
                        : const Text("Rescan"),
                    onPressed: () {
                      if (!state.scanning) {
                        context.read<ScanCubit>().rescan();
                      }
                    },
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
