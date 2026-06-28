import 'package:crossonic/data/repositories/appimage/appimage_repository.dart';
import 'package:crossonic/integrate_appimage_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppImageRepository extends Mock implements AppImageRepository {}

void main() {
  late MockAppImageRepository repo;

  setUp(() {
    repo = MockAppImageRepository();
  });

  IntegrateAppImageViewModel buildViewModel() =>
      IntegrateAppImageViewModel(appImageRepository: repo);

  group('check', () {
    test('shouldIntegrate true sets askToIntegrate true and notifies', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => true);
      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.askToIntegrate, isTrue);
      expect(notifications, 1);
      vm.dispose();
    });

    test('shouldIntegrate false leaves askToIntegrate false and no notify', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => false);
      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await vm.check();

      expect(vm.askToIntegrate, isFalse);
      expect(notifications, 0);
      vm.dispose();
    });
  });

  group('shownDialog', () {
    test('sets askToIntegrate to false', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => true);
      final vm = buildViewModel();
      await vm.check();
      expect(vm.askToIntegrate, isTrue);

      vm.shownDialog();

      expect(vm.askToIntegrate, isFalse);
      vm.dispose();
    });
  });

  group('disable', () {
    test('sets askToIntegrate false and calls disableIntegration', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => true);
      when(() => repo.disableIntegration()).thenAnswer((_) async {});
      final vm = buildViewModel();
      await vm.check();

      await vm.disable();

      expect(vm.askToIntegrate, isFalse);
      verify(() => repo.disableIntegration()).called(1);
      vm.dispose();
    });
  });

  group('integrate', () {
    test('Ok sets askToIntegrate false and returns Ok', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => true);
      when(() => repo.integrate()).thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      await vm.check();

      final result = await vm.integrate();

      expect(vm.askToIntegrate, isFalse);
      expect(result, isA<Ok>());
      vm.dispose();
    });

    test('Err sets askToIntegrate false and returns Err', () async {
      when(() => repo.shouldIntegrate()).thenAnswer((_) async => true);
      when(() => repo.integrate())
          .thenAnswer((_) async => Result.error(Exception('failed')));
      final vm = buildViewModel();
      await vm.check();

      final result = await vm.integrate();

      expect(vm.askToIntegrate, isFalse);
      expect(result, isA<Err>());
      vm.dispose();
    });
  });
}