import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/appearance.dart';
import 'package:crossonic/ui/settings/pages/appearance_viewmodel.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<String?> loadString(String key) async => null;
  @override
  Future<bool?> loadBool(String key) async => null;
}

void main() {
  late AppearanceSettings appearance;

  setUp(() {
    appearance = AppearanceSettings(keyValueRepository: _FakeKeyValue());
  });

  AppearanceViewModel buildViewModel() =>
      AppearanceViewModel(settings: appearance);

  test('constructor reads mode and dynamicColors from settings', () {
    final vm = buildViewModel();
    expect(vm.mode, appearance.themeMode);
    expect(vm.dynamicColors, appearance.dynamicColors);
    vm.dispose();
  });

  test('settings notification re-reads and notifies', () {
    final vm = buildViewModel();
    var notifications = 0;
    vm.addListener(() => notifications++);

    appearance.themeMode = ThemeMode.dark;

    expect(vm.mode, ThemeMode.dark);
    expect(notifications, greaterThanOrEqualTo(1));
    vm.dispose();
  });

  test('updateMode sets themeMode on underlying settings', () {
    final vm = buildViewModel();
    vm.updateMode(ThemeMode.light);
    expect(appearance.themeMode, ThemeMode.light);
    vm.dispose();
  });

  test('updateDynamicColors sets dynamicColors on underlying settings', () {
    final vm = buildViewModel();
    vm.updateDynamicColors(true);
    expect(appearance.dynamicColors, isTrue);
    vm.dispose();
  });
}