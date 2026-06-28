import 'package:crossonic/data/repositories/logger/log_repository.dart';
import 'package:crossonic/ui/settings/pages/logs/choose_log_session_page_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLogRepository extends Mock implements LogRepository {}

void main() {
  late MockLogRepository repo;

  setUp(() {
    repo = MockLogRepository();
  });

  ChooseLogSessionPageViewModel buildViewModel() =>
      ChooseLogSessionPageViewModel(logRepository: repo);

  group('sessions', () {
    test('empty immediately after construction', () async {
      when(() => repo.getSessions()).thenAnswer((_) async => []);
      final vm = buildViewModel();
      expect(vm.sessions, isEmpty);
      await Future.delayed(Duration.zero);
      vm.dispose();
    });

    test('after settle equals getSessions result and notifies', () async {
      final sessions = [DateTime(2024, 1, 1), DateTime(2024, 1, 2)];
      when(() => repo.getSessions()).thenAnswer((_) async => sessions);

      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.sessions, sessions);
      expect(notifications, 1);
      vm.dispose();
    });

    test('empty result still notifies (loaded-empty vs initial-empty)', () async {
      when(() => repo.getSessions()).thenAnswer((_) async => []);

      var notifications = 0;
      final vm = buildViewModel();
      vm.addListener(() => notifications++);

      await Future.delayed(Duration.zero);

      expect(vm.sessions, isEmpty);
      expect(notifications, 1);
      vm.dispose();
    });
  });
}