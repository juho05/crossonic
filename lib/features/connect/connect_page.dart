import 'package:crossonic/features/connect/state/connect_cubit.dart';
import 'package:crossonic/services/connect/connect_manager.dart';
import 'package:crossonic/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(context, "Connect", disableConnect: true),
      body: BlocProvider(
        create: (context) => ConnectCubit(context.read<ConnectManager>()),
        child:
            BlocBuilder<ConnectCubit, ConnectState>(builder: (context, state) {
          return ListView.builder(
            itemCount: state.devices.length,
            itemBuilder: (context, index) {
              final controlling = state.controllingDevice != null &&
                  state.controllingDevice == state.devices[index];
              return ListTile(
                iconColor: controlling ? Colors.green : null,
                leading: switch (state.devices[index].platform) {
                  "phone" => const Icon(Icons.smartphone),
                  "desktop" => const Icon(Icons.computer),
                  "web" => const Icon(Icons.web),
                  _ => controlling
                      ? const Icon(Icons.cast_connected)
                      : const Icon(Icons.cast)
                },
                title: Text(state.devices[index].name),
                onTap: () {
                  print(state.devices[index].id);
                },
              );
            },
          );
        }),
      ),
    );
  }
}
