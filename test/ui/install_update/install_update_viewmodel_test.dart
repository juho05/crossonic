import 'package:crossonic/data/repositories/auto_update/auto_update_repository.dart';
import 'package:crossonic/ui/install_update/install_update_viewmodel.dart';
import 'package:crossonic/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';

class MockAutoUpdateRepository extends Mock implements AutoUpdateRepository {}

void main() {
  late MockAutoUpdateRepository repo;

  setUp(() {
    repo = MockAutoUpdateRepository();
    when(() => repo.status).thenReturn(AutoUpdateStatus.initial);
    when(() => repo.downloadProgress)
        .thenAnswer((_) => BehaviorSubject.seeded(0.0).stream);
    when(() => repo.addListener(any())).thenReturn(null);
    when(() => repo.removeListener(any())).thenReturn(null);
  });

  InstallUpdateViewModel buildViewModel() =>
      InstallUpdateViewModel(autoUpdateRepository: repo);

  group('getters', () {
    test('status delegates to repo', () {
      when(() => repo.status).thenReturn(AutoUpdateStatus.downloading);
      final vm = buildViewModel();
      expect(vm.status, AutoUpdateStatus.downloading);
      vm.dispose();
    });

    test('downloadProgress delegates to repo', () {
      final subject = BehaviorSubject.seeded(0.5);
      when(() => repo.downloadProgress).thenAnswer((_) => subject.stream);
      final vm = buildViewModel();
      expect(vm.downloadProgress.value, 0.5);
      vm.dispose();
    });
  });

  group('repo notification forwarding', () {
    test('repo notification forwards to VM listeners', () {
      final vm = buildViewModel();
      var notifications = 0;
      vm.addListener(() => notifications++);

      final captured =
          verify(() => repo.addListener(captureAny())).captured.single
              as VoidCallback;
      captured();

      expect(notifications, 1);
      vm.dispose();
    });

    test('dispose removes listener from repo', () {
      final vm = buildViewModel();
      vm.dispose();
      verify(() => repo.removeListener(any())).called(1);
    });
  });

  group('installUpdate', () {
    test('Ok returns Ok', () async {
      when(() => repo.update()).thenAnswer((_) async => const Result.ok(null));
      final vm = buildViewModel();
      final result = await vm.installUpdate();
      expect(result, isA<Ok>());
      vm.dispose();
    });

    test('Err returns Err unchanged, no throw', () async {
      final error = Exception('update failed');
      when(() => repo.update()).thenAnswer((_) async => Result.error(error));
      final vm = buildViewModel();
      final result = await vm.installUpdate();
      expect(result, isA<Err>());
      vm.dispose();
    });
  });
}