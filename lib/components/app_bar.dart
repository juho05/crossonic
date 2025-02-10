import 'package:crossonic/components/state/layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

AppBar createAppBar(BuildContext context, String pageTitle) {
  final layout = context.read<Layout>();
  return AppBar(
    title: Text('Crossonic | $pageTitle'),
    actions: [
      if (layout.size == LayoutSize.mobile)
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => context.push("/settings"),
        ),
    ],
  );
}
