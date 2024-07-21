import 'package:crossonic/components/state/layout.dart';
import 'package:crossonic/services/connect/connect_manager.dart';
import 'package:crossonic/services/connect/models/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

AppBar createAppBar(BuildContext context, String pageTitle,
    {bool disableConnect = false}) {
  return AppBar(
    title: Text('Crossonic | $pageTitle'),
    actions: [
      if (!disableConnect)
        StreamBuilder<Device?>(
            stream: context.read<ConnectManager>().controllingDevice,
            builder: (context, snapshot) {
              return Builder(
                builder: (context) {
                  return IconButton(
                    icon: snapshot.data == null
                        ? const Icon(Icons.devices)
                        : Icon(
                            switch (snapshot.data!.platform) {
                              "phone" => Icons.smartphone,
                              "desktop" => Icons.computer,
                              "web" => Icons.language,
                              "speaker" => Icons.speaker_outlined,
                              _ => Icons.cast_connected
                            },
                            color: Colors.green),
                    onPressed: () => context.push("/connect"),
                  );
                },
              );
            }),
      Builder(builder: (context) {
        final layout = context.watch<Layout>();
        if (layout.size == LayoutSize.desktop) return const SizedBox();
        return IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push("/settings"),
        );
      }),
    ],
  );
}
