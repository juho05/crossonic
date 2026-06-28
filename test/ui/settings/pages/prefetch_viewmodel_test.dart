import 'package:crossonic/data/repositories/keyvalue/key_value_repository.dart';
import 'package:crossonic/data/repositories/settings/prefetch.dart';
import 'package:crossonic/data/repositories/settings/settings_repository.dart';
import 'package:crossonic/ui/settings/pages/prefetch_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class _FakeKeyValue extends Fake implements KeyValueRepository {
  @override
  Future<void> store<T>(String key, T value) async {}
  @override
  Future<void> remove(String key) async {}
  @override
  Future<bool?> loadBool(String key) async => null;
  @override
  Future<int?> loadInt(String key) async => null;
  @override
  Future<String?> loadString(String key) async => null;
}

void main() {
  late MockSettingsRepository settings;
  late PrefetchSettings prefetch;

  setUp(() {
    settings = MockSettingsRepository();
    prefetch = PrefetchSettings(keyValueRepository: _FakeKeyValue());
    when(() => settings.prefetch).thenReturn(prefetch);
  });

  PrefetchViewModel buildViewModel() => PrefetchViewModel(settings: settings);

  group('constructor', () {
    test('reads enabled and count from settings', () {
      final vm = buildViewModel();
      expect(vm.enabled, prefetch.enabled);
      expect(vm.count, prefetch.count);
      vm.dispose();
    });

    test('minCount matches PrefetchSettings.countMin', () {
      final vm = buildViewModel();
      expect(vm.minCount, PrefetchSettings.countMin);
      vm.dispose();
    });
  });

  group('settings notification', () {
    test('settings change re-reads and notifies', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      prefetch.enabled = true;

      expect(vm.enabled, isTrue);
      expect(notifications, greaterThanOrEqualTo(1));
      vm.dispose();
    });
  });

  group('enabled setter', () {
    test('true sets prefetch.enabled = true', () {
      final vm = buildViewModel();
      vm.enabled = true;
      expect(prefetch.enabled, isTrue);
      vm.dispose();
    });

    test('false calls prefetch.reset() resetting to default', () {
      prefetch.enabled = true;
      final vm = buildViewModel();

      vm.enabled = false;

      expect(prefetch.enabled, isFalse);
      vm.dispose();
    });
  });

  group('count setter', () {
    test('delegates to prefetch.count', () {
      final vm = buildViewModel();
      vm.count = 7;
      expect(prefetch.count, 7);
      vm.dispose();
    });
  });

  group('dispose', () {
    test('removes listener so settings changes no longer notify', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);
      vm.dispose();

      prefetch.enabled = true;

      expect(notifications, 0);
    });
  });
}