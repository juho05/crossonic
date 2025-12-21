import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class YearSelectorField extends StatelessWidget {
  final int year;

  final int? minYear;
  final int? maxYear;

  final void Function(int year) onChanged;

  const YearSelectorField({
    super.key,
    required this.year,
    required this.onChanged,
    this.minYear,
    this.maxYear,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          onTap: () async {
            final y = await showYearPicker(
              context: context,
              initialDate: DateTime(year),
              firstDate: minYear != null ? DateTime(minYear!) : null,
              lastDate: maxYear != null ? DateTime(maxYear!) : null,
              monthPickerDialogSettings: MonthPickerDialogSettings(
                dialogSettings: PickerDialogSettings(
                  blockScrolling:
                      kIsWeb ||
                      Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux,
                  dismissible: true,
                ),
              ),
            );
            if (y == null) return;
            onChanged(y);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Text(year.toString(), textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
