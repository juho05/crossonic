import 'package:crossonic/data/repositories/settings/home_page_layout.dart';
import 'package:flutter/material.dart';

class HomeLayoutViewModel extends ChangeNotifier {
  final HomeLayoutSettings _settings;

  List<HomeContentOption> activeComponents = [];
  List<HomeContentOption> inactiveComponents = [];

  HomeLayoutViewModel({
    required HomeLayoutSettings settings,
  }) : _settings = settings {
    _settings.addListener(_onSettingsChanged);
    _onSettingsChanged();
  }

  void _onSettingsChanged() {
    activeComponents = _settings.selectedOptions.toList();
    inactiveComponents = HomeContentOption.values
        .where((o) => !activeComponents.contains(o))
        .toList();
    notifyListeners();
  }

  void remove(int index) {
    final newList = List.of(activeComponents);
    newList.removeAt(index);
    _settings.selectedOptions = newList;
  }

  void reorder(int oldIndex, int newIndex) {
    final newList = List.of(activeComponents);
    if (oldIndex < newIndex) {
      newIndex--;
    }
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    _settings.selectedOptions = newList;
  }

  void add(int index) {
    final newList = List.of(activeComponents);
    newList.add(inactiveComponents[index]);
    _settings.selectedOptions = newList;
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }
}
