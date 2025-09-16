import 'package:crossonic/ui/common/dialogs/year_picker.dart';
import 'package:flutter/material.dart';

class YearSelectorField extends StatelessWidget {
  final int year;

  final int? minYear;
  final int? maxYear;

  final void Function(int year) onChanged;

  const YearSelectorField(
      {super.key,
      required this.year,
      required this.onChanged,
      this.minYear,
      this.maxYear});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          onTap: () async {
            final year = await YearPickerDialog.show(context,
                minYear: minYear, maxYear: maxYear);
            if (year == null) return;
            onChanged(year);
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
