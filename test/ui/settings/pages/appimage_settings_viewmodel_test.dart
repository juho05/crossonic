import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/ui/settings/pages/appimage_settings_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppImageRepository extends Mock implements AppImageRepository {}

void main() {
  late MockAppImageRepository repo;

  setUp(() {
    repo = MockAppImageRepository();
  });

  AppImageSettingsViewModel buildViewModel() =>
      AppImageSettingsViewModel(appImageRepository: repo);

  group('integrated', () {
    test('null synchronously after construction', () async {
      when(() => repo.isIntegrated()).thenAnswer((_) async => true);
      final vm = buildViewModel();
      expect(vm.integrated, isNull);
      await Future.delayed(Duration.zero);
      vm.dispose();
    });

    test('after settle equals isIntegrated() result (true) and notifies', () async {
      when(() => repo.isIntegrated()).thenAnswer((_) async => true);
      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.integrated, isTrue);
      expect(notifications, 1);
      vm.dispose();
    });

    test('after settle equals isIntegrated() result (false) and notifies', () async {
      when(() => repo.isIntegrated()).thenAnswer((_) async => false);
      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.integrated, isFalse);
      expect(notifications, 1);
      vm.dispose();
    });
  });

  group('integrate', () {
    test('Err returns Err, no restart attempted', () async {
      when(() => repo.isIntegrated()).thenAnswer((_) async => false);
      when(() => repo.integrate())
          .thenAnswer((_) async => Result.error(Exception('failed')));
      final vm = buildViewModel();
      await Future.delayed(Duration.zero);

      final result = await vm.integrate();

      expect(result, isA<Err>());
      vm.dispose();
    });
  });
}