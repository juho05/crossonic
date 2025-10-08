import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class YearPickerDialog extends StatefulWidget {
  final int? minYear;
  final int? maxYear;

  const YearPickerDialog({super.key, this.minYear, this.maxYear});

  static Future<int?> show(
    BuildContext context, {
    int? minYear,
    int? maxYear,
  }) {
    return showAdaptiveDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) => YearPickerDialog(
        minYear: minYear,
        maxYear: maxYear,
      ),
    );
  }

  @override
  State<YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<YearPickerDialog> {
  final _currentCentury = (DateTime.now().year / 100).floor() * 100;

  int? _century;
  int? _decade;

  @override
  Widget build(BuildContext context) {
    if (_century == null) {
      return _centuryPicker();
    } else if (_decade == null) {
      return _decadePicker();
    } else {
      return _yearPicker();
    }
  }

  Widget _centuryPicker() {
    final centuries =
        List.generate(10, (index) => _currentCentury - index * 100)
            .where((century) {
      if (widget.minYear != null &&
          century < (widget.minYear! / 100).floor() * 100) {
        return false;
      }
      if (widget.maxYear != null && century > widget.maxYear!) {
        return false;
      }
      return true;
    });
    if (centuries.isEmpty) {
      Navigator.pop(context);
      return const SimpleDialog();
    }
    if (centuries.length == 1) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _century = centuries.first;
        });
      });
      return const SimpleDialog();
    }
    return SimpleDialog(
      title: const Text("Select century"),
      children: centuries
          .map((century) => SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    _century = century;
                  });
                },
                child: Text(century.toString()),
              ))
          .toList(),
    );
  }

  Widget _decadePicker() {
    final decades = List.generate(10, (index) => index * 10).where((decade) {
      final decadeYear = _century! + decade;
      if (widget.minYear != null &&
          decadeYear < (widget.minYear! / 10).floor() * 10) {
        return false;
      }
      if (widget.maxYear != null && decadeYear > widget.maxYear!) {
        return false;
      }
      return true;
    });
    if (decades.isEmpty) {
      Navigator.pop(context);
      return const SimpleDialog();
    }
    if (decades.length == 1) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        setState(() {
          _decade = decades.first;
        });
      });
      return const SimpleDialog();
    }
    return SimpleDialog(
      title: const Text("Select decade"),
      children: decades
          .map((decade) => SimpleDialogOption(
                onPressed: () {
                  setState(() {
                    _decade = decade;
                  });
                },
                child: Text((_century! + decade).toString()),
              ))
          .toList(),
    );
  }

  Widget _yearPicker() {
    final years = List.generate(10, (index) => index).where((year) {
      final y = _century! + _decade! + year;
      if (widget.minYear != null && y < widget.minYear!) return false;
      if (widget.maxYear != null && y > widget.maxYear!) return false;
      return true;
    });
    if (years.isEmpty) {
      Navigator.pop(context);
      return const SimpleDialog();
    }
    if (years.length <= 1) {
      Navigator.pop(context, _century! + _decade! + years.first);
      return const SimpleDialog();
    }
    return SimpleDialog(
      title: const Text("Select year"),
      children: years
          .map((year) => SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(context, _century! + _decade! + year),
                child: Text((_century! + _decade! + year).toString()),
              ))
          .toList(),
    );
  }
}
