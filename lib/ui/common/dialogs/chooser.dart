// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

class ChooserDialog extends StatelessWidget {
  final String title;
  final List<String> options;
  const ChooserDialog._({
    required this.title,
    required this.options,
  });

  static Future<int?> choose(
      BuildContext context, String title, List<String> options,
      [bool autoChooseOnOneOption = true]) async {
    if (options.isEmpty) return null;
    if (autoChooseOnOneOption && options.length == 1) return 0;
    final index = await showAdaptiveDialog<int>(
      context: context,
      builder: (context) {
        return ChooserDialog._(
          title: title,
          options: options,
        );
      },
    );
    return index;
  }

  static Future<String?> chooseArtist(
      BuildContext context, List<({String id, String name})> artists) async {
    final index = await choose(
        context, "Choose an artist", artists.map((a) => a.name).toList());
    if (index == null) return null;
    return artists[index].id;
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(title),
      children: List.generate(
        options.length,
        (index) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, index),
          child: Text(options[index]),
        ),
      ),
    );
  }
}
